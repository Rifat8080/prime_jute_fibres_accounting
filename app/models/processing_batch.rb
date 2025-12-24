class ProcessingBatch < ApplicationRecord
  # columns: input_product_id, output_product_id, input_quantity, output_quantity, cost, input_jute_stock_id
  belongs_to :input_product, class_name: "Product", optional: true
  belongs_to :output_product, class_name: "Product", optional: true
  belongs_to :input_jute_stock, class_name: "JuteStock", optional: true
  # processing batches are associated to input_jute_stock; do not link to JutePurchase

  attr_accessor :_selected_input_stock, :_processing_applied

  validate :sufficient_input_stock
  validate :output_or_waste_present

  after_create :apply_processing

  def already_applied?
    @_processing_applied == true
  end

  private

  def sufficient_input_stock
    # Require an input quantity and either an input product or a specific input_jute_stock
    if input_quantity.blank?
      errors.add(:input_quantity, "is required")
      return
    end
    if input_product_id.blank? && input_jute_stock_id.blank?
      errors.add(:base, "Select an input product or a specific input stock")
      return
    end

    # If a specific stock id was provided, validate that single stock
    if input_jute_stock_id.present?
      js = JuteStock.find_by(id: input_jute_stock_id)
      unless js
        errors.add(:input_jute_stock_id, "is not valid")
        return
      end
      available = BigDecimal(js.quantity_value.to_s)
      needed = BigDecimal(input_quantity.to_s)
      if available < needed
        errors.add(:input_quantity, "not enough stock (available: #{available.to_s('F')} kg, requested: #{needed.to_s('F')} kg)")
      else
        @_selected_input_stock = js
      end
      return
    end

    # If input_product_id is provided, find all stocks for that product
    stocks = resolve_input_stocks

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

  def apply_processing
    return if already_applied?

    ActiveRecord::Base.transaction do
      Rails.logger.info("ProcessingBatch##{id} apply_processing start: input_product_id=#{input_product_id.inspect}, input_jute_stock_id=#{input_jute_stock_id.inspect}, input_quantity=#{input_quantity}")

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

    # Build candidate stocks using same logic as validation
    candidates = []
    if input_jute_stock_id.present?
      # Use the explicitly selected stock
      js = JuteStock.find_by(id: input_jute_stock_id)
      candidates = [ js ].compact
    elsif @_selected_input_stock.present?
      # Use the stock selected during validation
      candidates = [ @_selected_input_stock ]
    else
      # Fallback: resolve stocks using the same method as validation
      candidates = resolve_input_stocks.sort_by { |s| -BigDecimal(s.quantity_value.to_s) }
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
    elsif input_jute_stock_id.present?
      js = JuteStock.find_by(id: input_jute_stock_id)
      return js.stock_house if js
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
end
