class Shipment < ApplicationRecord
  belongs_to :sales_contract
  has_many :export_costs
  has_many :shipment_documents

  validates :shipment_date, presence: true
  validates :invoice_number, presence: true, uniqueness: true
  validates :total_bales, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :destination_port, presence: true
  validates :status, presence: true
end
