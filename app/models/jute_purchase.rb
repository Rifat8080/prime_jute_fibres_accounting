class JutePurchase < ApplicationRecord
  belongs_to :supplier
  belongs_to :stock_house
  has_many :procurement_costs, as: :costable, dependent: :destroy

  validates :purchase_date, presence: true
  validates :jute_variety, presence: true
  validates :quantity_kg, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rate_per_kg, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_house, presence: true

  before_save :calculate_total_amount
  before_update :set_old_quantity_kg
  after_save :update_jute_stock_on_save
  after_destroy :update_jute_stock_on_destroy

  def calculate_total_amount
    self.total_amount = (self.quantity_kg * self.rate_per_kg) + procurement_costs.sum(:amount)
  end

  private

  attr_accessor :old_quantity_kg

  def set_old_quantity_kg
    @old_quantity_kg = self.quantity_kg_was
  end

  def update_jute_stock_on_save
    quantity_change_kg = if new_record?
                           self.quantity_kg
                         else
                           self.quantity_kg - (old_quantity_kg || 0)
                         end
    adjust_jute_stock(quantity_change_kg)
  end

  def update_jute_stock_on_destroy
    adjust_jute_stock(-self.quantity_kg)
  end

  def adjust_jute_stock(quantity_kg_to_adjust)
    quantity_bales_to_adjust = quantity_kg_to_adjust / 100.0

    if self.stock_house
      jute_stock = JuteStock.find_or_initialize_by(
        stock_house: self.stock_house,
        jute_quality: self.jute_variety
      )
      jute_stock.quantity_bales ||= 0 # Initialize to 0 if nil
      jute_stock.quantity_bales += quantity_bales_to_adjust
      jute_stock.last_updated = Time.current
      jute_stock.save!
    else
      Rails.logger.error "No StockHouse associated with JutePurchase ID: #{self.id} for stock adjustment."
    end
  end
end
