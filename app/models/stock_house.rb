class StockHouse < ApplicationRecord
  has_many :jute_stocks

  validates :name, presence: true
  validates :location, presence: true
end
