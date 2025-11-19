class SalesContract < ApplicationRecord
  belongs_to :buyer
  has_many :shipments

  validates :contract_type, presence: true
  validates :contract_number, presence: true, uniqueness: true
  validates :contract_date, presence: true
end
