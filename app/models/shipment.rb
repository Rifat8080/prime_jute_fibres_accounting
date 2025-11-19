class Shipment < ApplicationRecord
  belongs_to :sales_contract
  belongs_to :stock_house
  has_many :export_costs
  has_many :shipment_documents

  validates :shipment_date, presence: true
  validates :invoice_number, presence: true, uniqueness: true
  validates :total_bales, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :destination_port, presence: true
  validates :status, presence: true
  validates :jute_quality, presence: true
  validates :stock_house, presence: true

  before_update :set_old_total_bales
  after_save :update_jute_stock_on_save
  after_destroy :update_jute_stock_on_destroy

  private

  attr_accessor :old_total_bales

  def set_old_total_bales
    @old_total_bales = self.total_bales_was
  end

  def update_jute_stock_on_save
    bales_to_adjust = if new_record?
                           -self.total_bales # Deduct for new shipment
                         else
                           (old_total_bales || 0) - self.total_bales # Adjust for updated shipment
                         end
    adjust_jute_stock(bales_to_adjust)
  end

  def update_jute_stock_on_destroy
    adjust_jute_stock(self.total_bales) # Add back for destroyed shipment
  end

  def adjust_jute_stock(bales_to_adjust)
    if self.stock_house
      jute_stock = JuteStock.find_or_initialize_by(
        stock_house: self.stock_house,
        jute_quality: self.jute_quality
      )
      jute_stock.quantity_bales ||= 0 # Initialize to 0 if nil
      jute_stock.quantity_bales += bales_to_adjust
      jute_stock.last_updated = Time.current
      jute_stock.save!
    else
      Rails.logger.error "No StockHouse associated with Shipment ID: #{self.id} for stock adjustment."
    end
  end
end
