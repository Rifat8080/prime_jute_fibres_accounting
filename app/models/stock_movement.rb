class StockMovement < ApplicationRecord
  belongs_to :jute_stock
  belongs_to :source, polymorphic: true

  validates :movement_type, presence: true, inclusion: { in: %w(in out) }
  validates :quantity_bales, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :movement_date, presence: true
end
