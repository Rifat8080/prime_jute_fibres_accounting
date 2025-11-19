class Buyer < ApplicationRecord
  has_many :sales_contracts

  validates :company_name, presence: true
  validates :contact_person, presence: true
  validates :email, presence: true, uniqueness: true
  validates :phone, presence: true
  validates :address, presence: true
  validates :country, presence: true
end
