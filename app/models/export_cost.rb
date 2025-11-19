class ExportCost < ApplicationRecord
  belongs_to :shipment

  validates :cost_type, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
