class JutePurchase < ApplicationRecord
  belongs_to :supplier
  belongs_to :stock_house, optional: true
  belongs_to :product, optional: true
  has_many :procurement_costs, as: :costable, dependent: :destroy

  validates :purchase_date, presence: true
  validates :product, presence: true
  validates :quantity_kg, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rate_per_kg, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :calculate_total_amount

  after_create :allocate_to_stock
  after_update :reallocate_stock, if: -> { saved_change_to_quantity_kg? || saved_change_to_product_id? || saved_change_to_stock_house_id? || saved_change_to_purchase_date? }

  def calculate_total_amount
    self.total_amount = (self.quantity_kg * self.rate_per_kg) + procurement_costs.sum(:amount)
  end

  def allocate_to_stock
    return unless quantity_kg && product_id
    house = (stock_house || StockHouse.first_or_create!(name: "Main Warehouse"))
    # Prefer a JuteStock record by product_id; if schema has jute_quality, set it to product name
    if JuteStock.table_exists? && JuteStock.column_names.include?("product_id")
      jute_stock = JuteStock.find_or_create_by!(stock_house: house, product_id: product_id) do |js|
        if js.has_attribute?("jute_quality")
          js.jute_quality ||= product&.name
        end
        if js.has_attribute?("quantity_bales")
          js.quantity_bales = 0
        else
          js.quantity = 0
        end
      end
    elsif JuteStock.table_exists? && JuteStock.column_names.include?("jute_quality")
      # fallback: match by product name stored in jute_quality
      jute_stock = JuteStock.find_or_create_by!(stock_house: house, jute_quality: product&.name) do |js|
        if js.has_attribute?("quantity_bales")
          js.quantity_bales = 0
        else
          js.quantity = 0
        end
      end
    else
      # final fallback: generic stock row
      jute_stock = JuteStock.find_or_create_by!(stock_house: house, product_id: nil) do |js|
        if js.has_attribute?("quantity_bales")
          js.quantity_bales = 0
        else
          js.quantity = 0
        end
      end
    end

    movement_attrs = { movement_type: "incoming" }

    # attach reference to this purchase using whichever polymorphic keys exist
    if StockMovement.column_names.include?("source_type") && StockMovement.column_names.include?("source_id")
      movement_attrs[:source_type] = self.class.name
      movement_attrs[:source_id] = self.id
    elsif StockMovement.column_names.include?("reference_type") && StockMovement.column_names.include?("reference_id")
      movement_attrs[:reference_type] = self.class.name
      movement_attrs[:reference_id] = self.id
    end

    # quantity field may be `quantity` or `quantity_bales`
    if StockMovement.new.has_attribute?("quantity")
      movement_attrs[:quantity] = quantity_kg
    else
      movement_attrs[:quantity_bales] = quantity_kg
    end

    # attach stock by id if supported, otherwise by product/warehouse fields
    if StockMovement.column_names.include?("jute_stock_id")
      movement_attrs[:jute_stock_id] = jute_stock.id
    else
      movement_attrs[:warehouse_id] = jute_stock.stock_house_id
      # if product_id exists on jute_stock, set it too
      movement_attrs[:product_id] = jute_stock.product_id if jute_stock.respond_to?(:product_id)
    end

    # Ensure product_id is set on the stock movement when possible
    if StockMovement.table_exists? && StockMovement.column_names.include?("product_id") && movement_attrs[:product_id].blank?
      movement_attrs[:product_id] = product_id
    end

    movement_attrs[:movement_date] = purchase_date || Date.today if StockMovement.column_names.include?("movement_date")

    # Attach purchase total amount to the stock movement when the column exists
    if StockMovement.table_exists? && StockMovement.column_names.include?("total_amount")
      movement_attrs[:total_amount] = total_amount
    end

    StockMovement.create!(movement_attrs)
  end

  def reallocate_stock
    # If only the stock_house changed (and not product or quantity), try an in-place move
    if saved_change_to_stock_house_id? && !saved_change_to_product_id? && !saved_change_to_quantity_kg?
      begin
        moved = try_move_stock_house
        return if moved
      rescue => e
        Rails.logger.warn("JutePurchase#reallocate_stock: in-place move failed: #{e.class} #{e.message}")
        # fall through to full reallocation
      end
    end

    # Remove any existing stock movements referencing this purchase so their after_destroy callbacks
    # revert previously applied quantities, then allocate again with current attributes.
    if StockMovement.table_exists?
      if StockMovement.column_names.include?("source_type") && StockMovement.column_names.include?("source_id")
        StockMovement.where(source_type: self.class.name, source_id: id).find_each(&:destroy)
      elsif StockMovement.column_names.include?("reference_type") && StockMovement.column_names.include?("reference_id")
        StockMovement.where(reference_type: self.class.name, reference_id: id).find_each(&:destroy)
      end
    end

    allocate_to_stock
  end

  # Attempt to move the existing JuteStock to the new stock_house without creating a new stock row.
  # This is only performed when it's safe (the stock row appears to belong solely to this purchase).
  def try_move_stock_house
    return false unless StockMovement.table_exists?

    # Find a representative stock movement created for this purchase
    mv = if StockMovement.column_names.include?("source_type") && StockMovement.column_names.include?("source_id")
           StockMovement.where(source_type: self.class.name, source_id: id).order(:created_at).first
    elsif StockMovement.column_names.include?("reference_type") && StockMovement.column_names.include?("reference_id")
           StockMovement.where(reference_type: self.class.name, reference_id: id).order(:created_at).first
    else
           nil
    end

    return false unless mv

    # Resolve the jute_stock record referenced by the movement (schema-aware)
    js = if mv.respond_to?(:jute_stock_id) && mv.jute_stock_id.present?
           JuteStock.find_by(id: mv.jute_stock_id)
    else
           JuteStock.find_by(product_id: mv.product_id, stock_house_id: mv.respond_to?(:warehouse_id) ? mv.warehouse_id : nil)
    end

    return false unless js

    # Safety checks: only move if this stock row seems to be exclusively created/used by this purchase
    related_sms = js.stock_movements.to_a
    # If there's more than one unrelated movement touching this stock, don't move it
    if related_sms.size > 1
      return false
    end

    # If the stock's current quantity doesn't match this purchase's quantity, avoid touching it
    # (user may expect partial balances). Only move if quantities match.
    if js.quantity_value != (quantity_kg || 0).to_d
      return false
    end

    # All checks passed: update the stock_house of the jute_stock to the new house
    js.update!(stock_house: stock_house)

    # Update the existing stock movement record to point to the new warehouse/stock where appropriate
    if mv.respond_to?(:warehouse_id) && mv.respond_to?(:write_attribute)
      mv.update!(warehouse_id: stock_house&.id)
    end

    true
  end

  private
end
