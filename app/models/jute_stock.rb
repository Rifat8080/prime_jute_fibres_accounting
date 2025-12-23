class JuteStock < ApplicationRecord
  belongs_to :stock_house
  has_many :stock_movements, dependent: :nullify

  validates :jute_quality, presence: true
  validates :quantity_bales, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
