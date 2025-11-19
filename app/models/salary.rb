class Salary < ApplicationRecord
  belongs_to :employee

  validates :payment_date, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :payment_period_start, presence: true
  validates :payment_period_end, presence: true
end
