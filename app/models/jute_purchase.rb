class JutePurchase < ApplicationRecord
  belongs_to :supplier
  has_many :procurement_costs, as: :costable, dependent: :destroy

  validates :purchase_date, presence: true
  validates :jute_variety, presence: true
  validates :quantity_kg, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rate_per_kg, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_total_amount

  def calculate_total_amount
    self.total_amount = (self.quantity_kg * self.rate_per_kg) + procurement_costs.sum(:amount)
  end

  private
end
