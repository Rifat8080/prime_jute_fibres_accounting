class Supplier < ApplicationRecord
  has_many :jute_purchases

  validates :name, presence: true
  validates :supplier_type, presence: true
end
