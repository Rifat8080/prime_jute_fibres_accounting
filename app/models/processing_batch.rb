class ProcessingBatch < ApplicationRecord
  # columns: input_product_id, output_product_id, input_quantity, output_quantity, cost, input_jute_stock_id
  belongs_to :input_product, class_name: 'Product', optional: true
  belongs_to :output_product, class_name: 'Product', optional: true
  belongs_to :input_jute_stock, class_name: 'JuteStock', optional: true
  attr_accessor :_selected_input_stock

  validate :sufficient_input_stock
  validate :output_or_waste_present

  after_create :apply_processing

  private

  def sufficient_input_stock
    return if input_product_id.blank? || input_quantity.blank?

    # consider all stocks for this product across houses
    stocks = []
    if JuteStock.table_exists?
      if JuteStock.column_names.include?('product_id')
        stocks = JuteStock.where(product_id: input_product_id).to_a
      end

      # fallback: match by jute_quality (case-insensitive) when product mapping not present
      if stocks.empty? && JuteStock.column_names.include?('jute_quality') && input_product&.name.present?
        stocks = JuteStock.where('lower(jute_quality) = ?', input_product.name.downcase).to_a
      end

      # final fallback: any stock rows without product mapping that have available quantity
      if stocks.empty?
        stocks = JuteStock.where(product_id: nil).to_a.select { |s| BigDecimal(s.quantity_value.to_s) > 0 }
      end
    end

    unless stocks.present?
      errors.add(:input_quantity, 'no input stock found for selected product')
      return
    end

    available = stocks.sum { |s| BigDecimal(s.quantity_value.to_s) }
    needed = BigDecimal(input_quantity.to_s)
    if available < needed
      errors.add(:input_quantity, "not enough stock (available: #{available.to_s('F')})")
    else
      # choose the stock with the largest available quantity to debit from by default
      @selected_input_stock = stocks.max_by { |s| BigDecimal(s.quantity_value.to_s) }
      # if a specific input_jute_stock was supplied, prefer it (validate it's part of the set)
      if input_jute_stock_id.present?
        supplied = stocks.find { |s| s.id.to_s == input_jute_stock_id.to_s }
        @selected_input_stock = supplied if supplied
      end
    end
  end

  def output_or_waste_present
    return if input_quantity.blank?
    if output_quantity.blank? && waste_quantity.blank?
      errors.add(:base, 'Either output_quantity or waste_quantity must be present')
      return
    end

    # ensure totals do not exceed input
    in_q = BigDecimal(input_quantity.to_s)
    out_q = output_quantity.present? ? BigDecimal(output_quantity.to_s) : BigDecimal('0')
    waste_q = waste_quantity.present? ? BigDecimal(waste_quantity.to_s) : BigDecimal('0')
    if out_q + waste_q > in_q
      errors.add(:base, 'Sum of output and waste cannot exceed input quantity')
    end
  end

  def find_stock_for_product(product_id, product_name=nil)
    # Try to find the most relevant stock row for the given product
    if product_id.present?
      stocks = JuteStock.where(product_id: product_id).to_a
      return stocks.max_by { |s| BigDecimal(s.quantity_value.to_s) } if stocks.present?
    end

    # If jute_quality column exists, try matching by product name
    if JuteStock.table_exists? && JuteStock.column_names.include?('jute_quality') && product_name.present?
      s = JuteStock.find_by(jute_quality: product_name)
      return s if s
    end

    # fallback: any stock row in main warehouse
    house = StockHouse.first
    return nil unless house
    JuteStock.find_by(stock_house: house)
  end

  def apply_processing
    # decrement input stock(s) and create outgoing movement(s)
    if input_quantity.present?
      required = BigDecimal(input_quantity.to_s)
      # build candidate stocks: prefer explicit input_jute_stock, otherwise all stocks for product sorted by largest quantity
      candidates = []
      if input_jute_stock.present?
        candidates = [input_jute_stock]
      elsif input_product_id.present?
        candidates = JuteStock.where(product_id: input_product_id).to_a.sort_by { |s| -BigDecimal(s.quantity_value.to_s) }
      end

      # fallback by name
      if candidates.blank? && JuteStock.table_exists? && JuteStock.column_names.include?('jute_quality') && input_product&.name.present?
        s = JuteStock.find_by(jute_quality: input_product.name)
        candidates = [s].compact
      end

      # consume across candidates until required fulfilled
      candidates.each do |stk|
        break if required <= 0
        available = BigDecimal(stk.quantity_value.to_s)
        next if available <= 0
        take = [available, required].min
        stk.decrement_quantity!(take)
        required -= take

        movement_attrs = { movement_type: 'outgoing' }
        if StockMovement.column_names.include?('source_type') && StockMovement.column_names.include?('source_id')
          movement_attrs[:source_type] = self.class.name
          movement_attrs[:source_id] = self.id
        elsif StockMovement.column_names.include?('reference_type') && StockMovement.column_names.include?('reference_id')
          movement_attrs[:reference_type] = self.class.name
          movement_attrs[:reference_id] = self.id
        end
        if StockMovement.new.has_attribute?('quantity')
          movement_attrs[:quantity] = take
        else
          movement_attrs[:quantity_bales] = take
        end
        if StockMovement.column_names.include?('jute_stock_id')
          movement_attrs[:jute_stock_id] = stk.id
        else
          movement_attrs[:warehouse_id] = stk.stock_house_id
          movement_attrs[:product_id] = stk.product_id
        end
        movement_attrs[:movement_date] = processed_date || Date.today if StockMovement.column_names.include?('movement_date')
        StockMovement.create!(movement_attrs)
      end

      if required > 0
        raise ActiveRecord::RecordInvalid.new(self), "Not enough input stock to consume required quantity"
      end
    end

    # Calculate output and waste quantities when one is missing
    in_q = input_quantity.present? ? BigDecimal(input_quantity.to_s) : BigDecimal('0')
    out_q = output_quantity.present? ? BigDecimal(output_quantity.to_s) : nil
    waste_q = waste_quantity.present? ? BigDecimal(waste_quantity.to_s) : nil
    if out_q.nil? && !waste_q.nil?
      out_q = in_q - waste_q
      self.update_column(:output_quantity, out_q) rescue nil
    elsif waste_q.nil? && !out_q.nil?
      waste_q = in_q - out_q
      self.update_column(:waste_quantity, waste_q) rescue nil
    end

    # determine an input stock reference for choosing houses (shared for output and waste)
    input_stock_local = if defined?(@selected_input_stock) && @selected_input_stock.present?
                          @selected_input_stock
                        elsif respond_to?(:input_jute_stock) && input_jute_stock.present?
                          input_jute_stock
                        elsif input_product_id.present?
                          JuteStock.where(product_id: input_product_id).first
                        else
                          nil
                        end

    # increment output stock
    if output_product_id && out_q.present? && out_q > 0
      # prefer same house as input_stock_local, otherwise first house
      house = input_stock_local&.stock_house || StockHouse.first
      output_stock = JuteStock.find_or_create_by(product_id: output_product_id, stock_house: house) do |js|
        if js.has_attribute?('jute_quality')
          js.jute_quality ||= output_product&.name || 'processed'
        end
        if js.has_attribute?('quantity_bales')
          js.quantity_bales = 0
        else
          js.quantity = 0
        end
      end
      output_stock.increment_quantity!(out_q)
      movement_attrs = { movement_type: 'incoming' }
      if StockMovement.column_names.include?('source_type') && StockMovement.column_names.include?('source_id')
        movement_attrs[:source_type] = self.class.name
        movement_attrs[:source_id] = self.id
      elsif StockMovement.column_names.include?('reference_type') && StockMovement.column_names.include?('reference_id')
        movement_attrs[:reference_type] = self.class.name
        movement_attrs[:reference_id] = self.id
      end
      if StockMovement.new.has_attribute?('quantity')
        movement_attrs[:quantity] = out_q
      else
        movement_attrs[:quantity_bales] = out_q
      end
      if StockMovement.column_names.include?('jute_stock_id')
        movement_attrs[:jute_stock_id] = output_stock.id
      else
        movement_attrs[:warehouse_id] = output_stock.stock_house_id
        movement_attrs[:product_id] = output_stock.product_id
      end
      movement_attrs[:movement_date] = processed_date || Date.today if StockMovement.column_names.include?('movement_date')
      StockMovement.create!(movement_attrs)
    end

    # increment waste stock (store waste as a product named 'Processing Waste')
    if waste_q.present? && waste_q > 0
      waste_product = Product.find_or_create_by(name: 'Processing Waste') do |p|
        p.product_type = 'waste'
        p.category = 'waste'
        p.unit = 'kg'
      end
      waste_house = input_stock_local&.stock_house || StockHouse.first
      waste_stock = JuteStock.find_or_create_by(product_id: waste_product.id, stock_house: waste_house) do |js|
        if js.has_attribute?('jute_quality')
          js.jute_quality ||= 'waste'
        end
        if js.has_attribute?('quantity_bales')
          js.quantity_bales = 0
        else
          js.quantity = 0
        end
      end
      waste_stock.increment_quantity!(waste_q)
      movement_attrs = { movement_type: 'incoming' }
      if StockMovement.column_names.include?('source_type') && StockMovement.column_names.include?('source_id')
        movement_attrs[:source_type] = self.class.name
        movement_attrs[:source_id] = self.id
      elsif StockMovement.column_names.include?('reference_type') && StockMovement.column_names.include?('reference_id')
        movement_attrs[:reference_type] = self.class.name
        movement_attrs[:reference_id] = self.id
      end
      if StockMovement.new.has_attribute?('quantity')
        movement_attrs[:quantity] = waste_q
      else
        movement_attrs[:quantity_bales] = waste_q
      end
      if StockMovement.column_names.include?('jute_stock_id')
        movement_attrs[:jute_stock_id] = waste_stock.id
      else
        movement_attrs[:warehouse_id] = waste_stock.stock_house_id
        movement_attrs[:product_id] = waste_stock.product_id
      end
      movement_attrs[:movement_date] = processed_date || Date.today if StockMovement.column_names.include?('movement_date')
      StockMovement.create!(movement_attrs)
    end
  rescue => e
    Rails.logger.error("ProcessingBatch apply_processing failed: #{e.message}")
    raise
  end
end
