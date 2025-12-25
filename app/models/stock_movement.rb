class StockMovement < ApplicationRecord
  belongs_to :jute_stock, optional: true
  belongs_to :source, polymorphic: true, optional: true

  validates :movement_type, presence: true
  validate :movement_quantity_present_and_number
  validates :movement_date, presence: true, if: -> { has_attribute?("movement_date") && self.class.column_names.include?("movement_date") }

  after_create :apply_to_stock
  after_destroy :revert_stock!

  def incoming?
    movement_type == "incoming"
  end

  def outgoing?
    movement_type == "outgoing"
  end

  def transfer?
    movement_type == "transfer"
  end

  def movement_quantity
    if has_attribute?("quantity")
      (self[:quantity] || 0).to_d
    elsif has_attribute?("quantity_bales")
      (self[:quantity_bales] || 0).to_d
    else
      0.to_d
    end
  end

  # Backwards-compatible setter: allow controllers or forms to set `jute_stock_id`
  # even when the DB schema doesn't have that column. Map to product/warehouse.
  def jute_stock_id=(val)
    if self.class.column_names.include?("jute_stock_id")
      write_attribute(:jute_stock_id, val)
    else
      js = JuteStock.find_by(id: val)
      if js
        self.product_id = js.product_id if js.respond_to?(:product_id)
        self.warehouse_id = js.stock_house_id if js.respond_to?(:stock_house_id)
      end
    end
  end

  def jute_stock_id
    if self.class.column_names.include?("jute_stock_id")
      read_attribute(:jute_stock_id)
    else
      jute_stock&.id
    end
  end

  # Safe helpers for views to avoid NoMethodError when columns differ
  def quantity_bales
    if has_attribute?("quantity_bales")
      self[:quantity_bales]
    elsif has_attribute?("quantity")
      self[:quantity]
    else
      movement_quantity
    end
  end

  def movement_date
    if has_attribute?("movement_date") && self[:movement_date].present?
      self[:movement_date]
    else
      created_at
    end
  end

  # Resolve the jute_stock for different schemas: prefer jute_stock_id, otherwise find by product and warehouse
  def jute_stock
    if self.class.column_names.include?("jute_stock_id")
      super
    else
      JuteStock.find_by(product_id: self.product_id, stock_house_id: self.warehouse_id)
    end
  end

  private

  def movement_quantity_present_and_number
    q = movement_quantity
    if q.nil?
      errors.add(:base, "movement quantity is required")
    elsif q < 0
      errors.add(:base, "movement quantity must be >= 0")
    end
  end

  def apply_to_stock
    return unless jute_stock

    if incoming?
      jute_stock.increment_quantity!(movement_quantity)
    elsif outgoing?
      jute_stock.decrement_quantity!(movement_quantity)
    end
    if jute_stock && jute_stock.respond_to?(:has_attribute?) && jute_stock.has_attribute?("last_updated") && self.class.column_names.include?("movement_date")
      jute_stock.update(last_updated: movement_date)
    else
      jute_stock&.touch
    end
  end

  def revert_stock!
    return unless jute_stock

    if incoming?
      jute_stock.decrement_quantity!(movement_quantity)
    elsif outgoing?
      jute_stock.increment_quantity!(movement_quantity)
    end
    if jute_stock && jute_stock.respond_to?(:has_attribute?) && jute_stock.has_attribute?("last_updated")
      jute_stock.update(last_updated: Time.current)
    else
      jute_stock&.touch
    end
  end

  # Allocated quantity is the portion of this incoming movement that has
  # already been assigned to processing batches. When present in the
  # schema (`allocated_quantity` decimal column) we keep it separate from
  # the original movement quantity so we can create multiple processing
  # batches that draw from the same incoming movement.
  def allocated_quantity
    if has_attribute?("allocated_quantity")
      (self[:allocated_quantity] || 0).to_d
    else
      0.to_d
    end
  end

  def available_quantity
    (movement_quantity || 0.to_d) - allocated_quantity
  end

  def allocate!(amount)
    return if amount.to_d <= 0
    if amount.to_d > available_quantity
      raise ArgumentError, "allocation amount #{amount} exceeds available quantity #{available_quantity}"
    end
    if has_attribute?("allocated_quantity")
      # Use a database-level update to avoid race conditions in concurrent requests.
      self.class.where(id: id).update_all([ "allocated_quantity = allocated_quantity + ?", amount.to_s ])
      reload
    else
      # If the column is not present, nothing persistent to update — caller should handle fallback.
    end
  end

  def release!(amount)
    return if amount.to_d <= 0
    if has_attribute?("allocated_quantity")
      self.class.where(id: id).update_all([ "allocated_quantity = GREATEST(allocated_quantity - ?, 0)", amount.to_s ])
      reload
    end
  end
end
