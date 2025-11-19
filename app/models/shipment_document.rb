class ShipmentDocument < ApplicationRecord
  belongs_to :shipment
  has_one_attached :file

  validates :document_type, presence: true
end
