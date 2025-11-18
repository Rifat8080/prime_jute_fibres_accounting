class ShipmentDocument < ApplicationRecord
  has_one_attached :file
end
