class Account < ApplicationRecord
  has_many :transactions

  validates :name, presence: true
  validates :account_type, presence: true
  validates :account_number, presence: true, uniqueness: true
  validates :bank_name, presence: true
  validates :current_balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
