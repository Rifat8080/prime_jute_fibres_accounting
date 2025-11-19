class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :related_entity, polymorphic: true

  validates :transaction_date, presence: true
  validates :transaction_type, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, presence: true
end
