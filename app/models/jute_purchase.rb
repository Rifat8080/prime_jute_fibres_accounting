class JutePurchase < ApplicationRecord
  belongs_to :supplier
  has_many :procurement_costs, as: :costable

  validates :purchase_date, presence: true
  validates :jute_variety, presence: true
  validates :quantity_kg, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :rate_per_kg, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
