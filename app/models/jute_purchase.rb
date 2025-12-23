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

  def calculate_total_amount
    self.total_amount = (self.quantity_kg * self.rate_per_kg) + procurement_costs.sum(:amount)
  end

  def allocate_to_stock
    return unless quantity_kg && product_id
    house = (stock_house || StockHouse.first_or_create!(name: 'Main Warehouse'))
    # Prefer a JuteStock record by product_id; if schema has jute_quality, set it to product name
    if JuteStock.table_exists? && JuteStock.column_names.include?('product_id')
      jute_stock = JuteStock.find_or_create_by!(stock_house: house, product_id: product_id) do |js|
        if js.has_attribute?('jute_quality')
          js.jute_quality ||= product&.name
        end
        if js.has_attribute?('quantity_bales')
          js.quantity_bales = 0
        else
          js.quantity = 0
        end
      end
    elsif JuteStock.table_exists? && JuteStock.column_names.include?('jute_quality')
      # fallback: match by product name stored in jute_quality
      jute_stock = JuteStock.find_or_create_by!(stock_house: house, jute_quality: product&.name) do |js|
        if js.has_attribute?('quantity_bales')
          js.quantity_bales = 0
        else
          js.quantity = 0
        end
      end
    else
      # final fallback: generic stock row
      jute_stock = JuteStock.find_or_create_by!(stock_house: house, product_id: nil) do |js|
        if js.has_attribute?('quantity_bales')
          js.quantity_bales = 0
        else
          js.quantity = 0
        end
      end
    end

    movement_attrs = { movement_type: 'incoming' }

    # attach reference to this purchase using whichever polymorphic keys exist
    if StockMovement.column_names.include?('source_type') && StockMovement.column_names.include?('source_id')
      movement_attrs[:source_type] = self.class.name
      movement_attrs[:source_id] = self.id
    elsif StockMovement.column_names.include?('reference_type') && StockMovement.column_names.include?('reference_id')
      movement_attrs[:reference_type] = self.class.name
      movement_attrs[:reference_id] = self.id
    end

    # quantity field may be `quantity` or `quantity_bales`
    if StockMovement.new.has_attribute?('quantity')
      movement_attrs[:quantity] = quantity_kg
    else
      movement_attrs[:quantity_bales] = quantity_kg
    end

    # attach stock by id if supported, otherwise by product/warehouse fields
    if StockMovement.column_names.include?('jute_stock_id')
      movement_attrs[:jute_stock_id] = jute_stock.id
    else
      movement_attrs[:warehouse_id] = jute_stock.stock_house_id
      # if product_id exists on jute_stock, set it too
      movement_attrs[:product_id] = jute_stock.product_id if jute_stock.respond_to?(:product_id)
    end

    movement_attrs[:movement_date] = purchase_date || Date.today if StockMovement.column_names.include?('movement_date')

    StockMovement.create!(movement_attrs)
  end

  private
end
