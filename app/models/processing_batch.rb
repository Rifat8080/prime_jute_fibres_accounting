class ProcessingBatch < ApplicationRecord
  # columns: input_product_id, output_product_id, input_quantity, output_quantity, cost
  belongs_to :input_product, class_name: "Product", optional: true
  belongs_to :output_product, class_name: "Product", optional: true
  # ProcessingBatch used to reference an explicit `input_jute_stock` (JuteStock).
  # Processing should now be represented via `StockMovement` records. The
  # direct association to `JuteStock` is intentionally removed from the model.

  attr_accessor :_selected_input_stock, :_processing_applied
  # transient reference to a StockMovement used as source for this processing
  attr_accessor :source_stock_movement_id
  # transient reference to a JuteStock used as source for available quantity
  attr_accessor :source_jute_stock_id
  belongs_to :stock_movement, optional: true

  before_validation :apply_source_stock_movement_price, if: -> { source_stock_movement_id.present? }
  before_validation :apply_source_jute_stock_allocation, if: -> { source_jute_stock_id.present? }
  validate :stock_movement_quantity_available
  validate :stock_movement_allowed
  validate :stock_jute_movements_quantity_available
  has_many :procurement_costs, as: :costable, dependent: :destroy
  accepts_nested_attributes_for :procurement_costs, allow_destroy: true, reject_if: proc { |attrs| attrs["amount"].blank? && attrs["cost_type"].blank? }

  validate :sufficient_input_stock
  validate :output_or_waste_present

  after_create :apply_processing
  after_destroy :release_stock_movement_allocation

  def already_applied?
    @_processing_applied == true
  end

  private

  def sufficient_input_stock
    # Require an input quantity and an input product (processing is product-driven)
    if input_quantity.blank?
      errors.add(:input_quantity, "is required")
      return
    end

    if input_product_id.blank?
      errors.add(:base, "Select an input product")
      return
    end

    # Find all stocks for the input product and ensure enough quantity exists
    stocks = resolve_input_stocks

    # If a source stock movement was provided, prefer the stock referenced by it
    if source_stock_movement_id.present? && defined?(StockMovement) && StockMovement.table_exists?
      sm = StockMovement.find_by(id: source_stock_movement_id)
      if sm
        js = if sm.respond_to?(:jute_stock_id) && sm.jute_stock_id.present?
               JuteStock.find_by(id: sm.jute_stock_id)
        else
               JuteStock.find_by(product_id: sm.product_id, stock_house_id: sm.respond_to?(:warehouse_id) ? sm.warehouse_id : nil)
        end
        @_selected_input_stock = js if js
      end
    end

    unless stocks.present?
      errors.add(:input_quantity, "no input stock found for selected product")
      return
    end

    available = stocks.sum { |s| BigDecimal(s.quantity_value.to_s) }
    needed = BigDecimal(input_quantity.to_s)
    if available < needed
      errors.add(:input_quantity, "not enough stock (available: #{available.to_s('F')} kg, requested: #{needed.to_s('F')} kg)")
    else
      # Store the selected stock for use in apply_processing
      @_selected_input_stock = stocks.max_by { |s| BigDecimal(s.quantity_value.to_s) }
    end
  end

  def output_or_waste_present
    return if input_quantity.blank?
    if output_quantity.blank? && waste_quantity.blank?
      errors.add(:base, "Either output_quantity or waste_quantity must be present")
      return
    end

    # ensure totals do not exceed input
    in_q = BigDecimal(input_quantity.to_s)
    out_q = output_quantity.present? ? BigDecimal(output_quantity.to_s) : BigDecimal("0")
    waste_q = waste_quantity.present? ? BigDecimal(waste_quantity.to_s) : BigDecimal("0")
    if out_q + waste_q > in_q
      errors.add(:base, "Sum of output and waste cannot exceed input quantity")
    end
  end

  def find_stock_for_product(product_id, product_name = nil)
    # Try to find the most relevant stock row for the given product
    if product_id.present?
      stocks = JuteStock.where(product_id: product_id).to_a
      return stocks.max_by { |s| BigDecimal(s.quantity_value.to_s) } if stocks.present?
    end

    # If jute_quality column exists, try matching by product name
    if JuteStock.table_exists? && JuteStock.column_names.include?("jute_quality") && product_name.present?
      s = JuteStock.find_by(jute_quality: product_name)
      return s if s
    end

    # fallback: any stock row in main warehouse
    house = StockHouse.first
    return nil unless house
    JuteStock.find_by(stock_house: house)
  end

  # Resolve input stocks using the same logic as validation
  def resolve_input_stocks
    stocks = []
    return stocks unless JuteStock.table_exists?

    if JuteStock.column_names.include?("product_id") && input_product_id.present?
      stocks = JuteStock.where(product_id: input_product_id).to_a
    end

    # fallback: match by jute_quality (case-insensitive) when product mapping not present
    if stocks.empty? && JuteStock.column_names.include?("jute_quality") && input_product&.name.present?
      stocks = JuteStock.where("lower(jute_quality) = ?", input_product.name.downcase).to_a
    end

    # final fallback: any stock rows without product mapping that have available quantity
    if stocks.empty?
      stocks = JuteStock.where(product_id: nil).to_a.select { |s| BigDecimal(s.quantity_value.to_s) > 0 }
    end

    stocks
  end

  def apply_source_stock_movement_price
    return unless defined?(StockMovement) && StockMovement.table_exists?
    sm = StockMovement.find_by(id: source_stock_movement_id || stock_movement_id)
    return unless sm

    # If the movement is not an incoming movement, disallow using it as source
    if sm.outgoing? || sm.transfer?
      errors.add(:stock_movement_id, "cannot be used as source (movement type #{sm.movement_type})")
      return
    end

    # Prefill quantity from the movement if not already set
    if input_quantity.blank?
      qty = if sm.respond_to?(:movement_quantity)
              sm.movement_quantity
      elsif sm.respond_to?(:quantity) && sm.quantity.present?
              sm.quantity
      elsif sm.respond_to?(:quantity_bales) && sm.quantity_bales.present?
              sm.quantity_bales
      else
              nil
      end
      self.input_quantity = qty if qty.present?
    end

    # Allocate cost proportionally from the stock movement's total_amount when available
    if sm.respond_to?(:total_amount) && sm.total_amount.present? && sm.respond_to?(:movement_quantity) && sm.movement_quantity.to_d > 0
      begin
        movement_qty = BigDecimal(sm.movement_quantity.to_s)
        take = BigDecimal(input_quantity.to_s)
        proportion = [ take / movement_qty, 1.to_d ].min
        allocated = BigDecimal(sm.total_amount.to_s) * proportion
        write_attribute(:input_cost_allocated, allocated)
        write_attribute(:input_unit_cost_at_processing, (allocated / take)) if take > 0
      rescue => _e
        # ignore allocation errors
      end
    end
  end

  # Allocate cost when sourcing from a JuteStock (multiple stock movements)
  def apply_source_jute_stock_allocation
    return unless defined?(StockMovement) && StockMovement.table_exists?
    js = JuteStock.find_by(id: source_jute_stock_id)
    return unless js

    required = BigDecimal(input_quantity.to_s) rescue nil
    return unless required && required > 0

    # Find candidate incoming movements for this stock (FIFO by movement_date/created_at)
    movements = if StockMovement.column_names.include?("jute_stock_id")
      StockMovement.where(jute_stock_id: js.id, movement_type: "incoming").order(Arel.sql("COALESCE(movement_date, created_at) ASC"))
    else
      StockMovement.where(product_id: js.product_id, warehouse_id: js.stock_house_id, movement_type: "incoming").order(Arel.sql("COALESCE(movement_date, created_at) ASC"))
    end

    return if movements.none?

    allocated_total = 0.to_d
    remaining = required

    movements.find_each do |m|
      break if remaining <= 0
      m_qty = begin
        BigDecimal(m.respond_to?(:movement_quantity) ? m.movement_quantity.to_s : (m.quantity || m.quantity_bales || "0").to_s)
      rescue
        0.to_d
      end
      next if m_qty <= 0
      take = [ m_qty, remaining ].min
      if m.respond_to?(:total_amount) && m.total_amount.present? && m_qty > 0
        unit = BigDecimal(m.total_amount.to_s) / m_qty
        allocated_total += unit * take
      end
      remaining -= take
    end

    # store allocated cost and unit cost (unit cost = allocated_total / required)
    if allocated_total > 0
      write_attribute(:input_cost_allocated, allocated_total)
      write_attribute(:input_unit_cost_at_processing, (allocated_total / required))
    end
  end

  def stock_movement_quantity_available
    return if stock_movement_id.blank? || input_quantity.blank?
    return unless defined?(StockMovement) && StockMovement.table_exists?

    sm = StockMovement.find_by(id: stock_movement_id)
    return unless sm

    begin
      # Prefer the movement's available_quantity if provided by the model
      if sm.respond_to?(:available_quantity)
        avail = sm.available_quantity
        if BigDecimal(input_quantity.to_s) > avail
          errors.add(:input_quantity, "exceeds available quantity on the referenced stock movement (available: #{avail.to_s('F')} kg)")
        end
      else
        movement_qty = BigDecimal(sm.respond_to?(:movement_quantity) ? sm.movement_quantity.to_s : (sm.quantity || sm.quantity_bales || "0").to_s)
        existing = ProcessingBatch.where(stock_movement_id: sm.id).where.not(id: id).sum(:input_quantity).to_d
        new_total = existing + BigDecimal(input_quantity.to_s)
        if new_total > movement_qty
          errors.add(:input_quantity, "exceeds available quantity on the referenced stock movement (available: ")
          errors.add(:stock_movement_id, "total assigned to processing (#{new_total.to_s('F')}) exceeds movement quantity (#{movement_qty.to_s('F')})")
        end
      end
    rescue => e
      Rails.logger.warn("ProcessingBatch#stock_movement_quantity_available check failed: #{e.class} #{e.message}")
    end
  end

  def stock_movement_allowed
    return if stock_movement_id.blank?
    return unless defined?(StockMovement) && StockMovement.table_exists?
    sm = StockMovement.find_by(id: stock_movement_id)
    return unless sm
    if sm.outgoing? || sm.transfer?
      errors.add(:stock_movement_id, "cannot be used as source because movement is #{sm.movement_type}")
    end
  end

  # When a jute stock is provided as the source, ensure the total input_quantity
  # assigned across processing batches referencing movements for that stock
  # does not exceed the sum of those stock movements' quantities.
  def stock_jute_movements_quantity_available
    return if source_jute_stock_id.blank? || input_quantity.blank?
    return unless defined?(StockMovement) && StockMovement.table_exists?

    # Find relevant stock movements for the jute stock: prefer direct jute_stock_id, fallback to product+warehouse
    movement_scope = StockMovement.none
    if StockMovement.column_names.include?("jute_stock_id")
      movement_scope = StockMovement.where(jute_stock_id: source_jute_stock_id)
    else
      js = JuteStock.find_by(id: source_jute_stock_id)
      if js
        movement_scope = StockMovement.where(product_id: js.product_id, warehouse_id: js.stock_house_id)
      end
    end

    return if movement_scope.none?

    total_available = movement_scope.sum do |m|
      begin
        BigDecimal(m.respond_to?(:movement_quantity) ? m.movement_quantity.to_s : (m.quantity || m.quantity_bales || "0").to_s)
      rescue
        0.to_d
      end
    end.to_d

    assigned = ProcessingBatch.where(stock_movement_id: movement_scope.pluck(:id)).where.not(id: id).sum(:input_quantity).to_d
    new_total = assigned + BigDecimal(input_quantity.to_s)
    if new_total > total_available
      errors.add(:input_quantity, "exceeds available total quantity for selected stock (available: #{total_available.to_s('F')} kg, assigned: #{assigned.to_s('F')} kg)")
    end
  end

  def apply_processing
    return if already_applied?

    ActiveRecord::Base.transaction do
      Rails.logger.info("ProcessingBatch##{id} apply_processing start: input_product_id=#{input_product_id.inspect}, input_quantity=#{input_quantity}")

      # Process input consumption
      consume_input_stocks

      # Calculate output and waste quantities when one is missing
      calculate_output_waste

      # Process output and waste
      create_output_stock
      create_waste_stock

      # Mark as applied
      @_processing_applied = true
      Rails.logger.info("ProcessingBatch##{id} apply_processing completed successfully")
    end
  rescue => e
    Rails.logger.error("ProcessingBatch##{id} apply_processing failed: #{e.class} #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end

  def consume_input_stocks
    return unless input_quantity.present?

    required = BigDecimal(input_quantity.to_s)

    # If a source stock movement was supplied, consume from it first (but do not re-create an outgoing movement for that portion)
    if source_stock_movement_id.present? && defined?(StockMovement) && StockMovement.table_exists?
      sm = StockMovement.find_by(id: source_stock_movement_id)
      if sm
        # Prefer the movement's available_quantity helper if it exists
        available = if sm.respond_to?(:available_quantity)
                      sm.available_quantity
        else
                      BigDecimal(sm.respond_to?(:movement_quantity) ? sm.movement_quantity.to_s : (sm.quantity || sm.quantity_bales || "0").to_s)
        end

        take = [ available, required ].min
        if take > 0
          Rails.logger.info("ProcessingBatch##{id} consuming #{take} from existing StockMovement #{sm.id}")
          # Persist allocation on the movement when supported to avoid creating an outgoing movement
          if sm.respond_to?(:allocate!)
            sm.allocate!(take)
          end
          required -= take
        end
      end
    end

    # Build candidate stocks using same logic as validation
    candidates = if @_selected_input_stock.present?
      [ @_selected_input_stock ]
    else
      resolve_input_stocks.sort_by { |s| -BigDecimal(s.quantity_value.to_s) }
    end

    Rails.logger.info("ProcessingBatch##{id} candidates: [#{candidates.map { |s| "#{s.id}:#{s.quantity_value}" }.join(', ')}]")

    if candidates.empty?
      raise ActiveRecord::RecordInvalid.new(self), "No input stock found for processing"
    end

    # Consume across candidates until required fulfilled
    candidates.each do |stk|
      break if required <= 0
      available = BigDecimal(stk.quantity_value.to_s)
      Rails.logger.info("ProcessingBatch##{id} candidate #{stk.id} available=#{available}")
      next if available <= 0

      take = [ available, required ].min
      Rails.logger.info("ProcessingBatch##{id} taking #{take} from stock #{stk.id}")

      # Create outgoing movement (which will decrement stock via callback)
      create_stock_movement(
        stock: stk,
        movement_type: "outgoing",
        quantity: take
      )

      required -= take
    end

    if required > 0
      raise ActiveRecord::RecordInvalid.new(self), "Not enough input stock to consume required quantity (short by #{required.to_s('F')} kg)"
    end
  end

  def calculate_output_waste
    in_q = input_quantity.present? ? BigDecimal(input_quantity.to_s) : BigDecimal("0")
    out_q = output_quantity.present? ? BigDecimal(output_quantity.to_s) : nil
    waste_q = waste_quantity.present? ? BigDecimal(waste_quantity.to_s) : nil

    if out_q.nil? && !waste_q.nil?
      out_q = in_q - waste_q
      self.update_column(:output_quantity, out_q) if out_q >= 0
    elsif waste_q.nil? && !out_q.nil?
      waste_q = in_q - out_q
      self.update_column(:waste_quantity, waste_q) if waste_q >= 0
    end
  end

  def create_output_stock
    return unless output_product_id.present?

    out_q = output_quantity.present? ? BigDecimal(output_quantity.to_s) : BigDecimal("0")
    return unless out_q > 0

    # Determine house from input stock
    house = determine_stock_house

    output_stock = JuteStock.find_or_create_by!(product_id: output_product_id, stock_house: house) do |js|
      if js.has_attribute?("jute_quality")
        js.jute_quality = output_product&.name || "processed"
      end
      if js.has_attribute?("quantity_bales")
        js.quantity_bales = 0
      else
        js.quantity = 0
      end
    end

    # Create incoming movement (which will increment stock via callback)
    create_stock_movement(
      stock: output_stock,
      movement_type: "incoming",
      quantity: out_q
    )
  end

  def create_waste_stock
    waste_q = waste_quantity.present? ? BigDecimal(waste_quantity.to_s) : BigDecimal("0")
    return unless waste_q > 0

    waste_product = Product.find_or_create_by!(name: "Processing Waste") do |p|
      p.product_type = "waste"
      p.category = "waste"
      p.unit = "kg"
    end

    house = determine_stock_house

    waste_stock = JuteStock.find_or_create_by!(product_id: waste_product.id, stock_house: house) do |js|
      if js.has_attribute?("jute_quality")
        js.jute_quality = "waste"
      end
      if js.has_attribute?("quantity_bales")
        js.quantity_bales = 0
      else
        js.quantity = 0
      end
    end

    # Create incoming movement (which will increment stock via callback)
    create_stock_movement(
      stock: waste_stock,
      movement_type: "incoming",
      quantity: waste_q
    )
  end

  def determine_stock_house
    # Try to use the same house as the input stock
    if @_selected_input_stock.present?
      return @_selected_input_stock.stock_house
    elsif input_product_id.present?
      js = JuteStock.where(product_id: input_product_id).first
      return js.stock_house if js
    end

    # Fallback to first available house
    StockHouse.first || StockHouse.create!(name: "Main Warehouse")
  end

  def create_stock_movement(stock:, movement_type:, quantity:)
    movement_attrs = {
      movement_type: movement_type
    }

    # Set movement_date only if the column exists
    if StockMovement.column_names.include?("movement_date")
      movement_attrs[:movement_date] = processed_date || Date.today
    end

    # Set polymorphic reference to this processing batch
    if StockMovement.column_names.include?("source_type") && StockMovement.column_names.include?("source_id")
      movement_attrs[:source_type] = self.class.name
      movement_attrs[:source_id] = self.id
    elsif StockMovement.column_names.include?("reference_type") && StockMovement.column_names.include?("reference_id")
      movement_attrs[:reference_type] = self.class.name
      movement_attrs[:reference_id] = self.id
    end

    # Set quantity field
    if StockMovement.new.has_attribute?("quantity")
      movement_attrs[:quantity] = quantity
    else
      movement_attrs[:quantity_bales] = quantity
    end

    # Set stock reference
    if StockMovement.column_names.include?("jute_stock_id")
      movement_attrs[:jute_stock_id] = stock.id
    else
      movement_attrs[:warehouse_id] = stock.stock_house_id
      movement_attrs[:product_id] = stock.product_id
    end

    StockMovement.create!(movement_attrs)
  end

  def release_stock_movement_allocation
    return unless stock_movement_id.present?
    return unless defined?(StockMovement) && StockMovement.table_exists?
    sm = StockMovement.find_by(id: stock_movement_id)
    return unless sm
    begin
      if sm.respond_to?(:release!)
        sm.release!(BigDecimal(input_quantity.to_s))
      end
    rescue => e
      Rails.logger.warn("Failed to release allocation for ProcessingBatch #{id} on StockMovement #{sm.id}: #{e.class} #{e.message}")
    end
  end
end
