class JuteStock < ApplicationRecord
  belongs_to :stock_house
  belongs_to :product, optional: true
  # Define a safe association for stock movements. Some databases store a
  # direct `jute_stock_id` FK on `stock_movements`; others link by
  # `product_id` + `warehouse_id` (stock_house). Create a fallback
  # association name and expose a schema-aware `stock_movements` method.
  if defined?(StockMovement) && StockMovement.table_exists? && StockMovement.column_names.include?("jute_stock_id")
    has_many :stock_movements_assoc, class_name: "StockMovement", foreign_key: "jute_stock_id", dependent: :nullify
  else
    # no direct association defined — we'll query dynamically in the method below
  end

  validates :jute_quality, presence: true, if: -> { has_attribute?("jute_quality") }
  validate :quantity_present_and_number

  def quantity_field
    if has_attribute?("quantity_bales")
      "quantity_bales"
    else
      "quantity"
    end
  end

  # Safe accessor for views — some schemas don't have `jute_quality`.
  def jute_quality
    has_attribute?("jute_quality") ? self[:jute_quality] : nil
  end

  # Provide a `quantity_bales` method for views; fall back to whichever
  # quantity column exists.
  def quantity_bales
    if has_attribute?("quantity_bales")
      self[:quantity_bales]
    else
      # fall back to `quantity` column if that exists
      has_attribute?("quantity") ? self[:quantity] : nil
    end
  end

  # Friendly last-updated display used in views
  def last_updated
    try(:updated_at) || try(:created_at)
  end

  # Schema-aware accessor for related stock movements. If a direct
  # `jute_stock_id` association exists we use it; otherwise we look up
  # movements by `product_id` and `warehouse_id` (stock_house_id).
  def stock_movements
    if respond_to?(:stock_movements_assoc)
      stock_movements_assoc
    else
      if defined?(StockMovement) && StockMovement.table_exists?
        StockMovement.where(product_id: product_id, warehouse_id: stock_house_id)
      else
        StockMovement.none
      end
    end
  end

  # Return ProcessingBatch records that affected this stock (via stock movements or direct input_jute_stock link)
  def processing_batches
    return ProcessingBatch.none unless defined?(ProcessingBatch) && ProcessingBatch.table_exists?

    ids = []
    if defined?(StockMovement) && StockMovement.table_exists?
      sm = stock_movements
      if StockMovement.column_names.include?("source_type") && StockMovement.column_names.include?("source_id")
        ids += sm.where(source_type: "ProcessingBatch").pluck(:source_id) rescue []
      end
      if StockMovement.column_names.include?("reference_type") && StockMovement.column_names.include?("reference_id")
        ids += sm.where(reference_type: "ProcessingBatch").pluck(:reference_id) rescue []
      end
    end

    if ProcessingBatch.column_names.include?("input_jute_stock_id")
      ids += ProcessingBatch.where(input_jute_stock_id: id).pluck(:id) rescue []
    end

    ProcessingBatch.where(id: ids.uniq)
  end

  def quantity_value
    (self[quantity_field] || 0).to_d
  end

  def increment_quantity!(n)
    n = BigDecimal(n.to_s)
    write_attribute(quantity_field, quantity_value + n)
    save!
  end

  def decrement_quantity!(n)
    n = BigDecimal(n.to_s)
    new_val = quantity_value - n
    if new_val < 0
      errors.add(:base, "not enough stock (available: #{quantity_value.to_s('F')}, requested: #{n.to_s('F')})")
      raise ActiveRecord::RecordInvalid.new(self)
    end
    write_attribute(quantity_field, new_val)
    save!
  end

  private

  def quantity_present_and_number
    val = self[quantity_field]
    if val.nil?
      errors.add(:base, "quantity is required")
    elsif !val.is_a?(Numeric) && !(val.is_a?(BigDecimal))
      errors.add(:base, "quantity must be a number")
    elsif val.to_d < 0
      errors.add(:base, "quantity cannot be negative")
    end
  end
end
