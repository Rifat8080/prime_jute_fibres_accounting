class Employee < ApplicationRecord
  has_many :salaries

  validates :name, presence: true
  validates :employee_type, presence: true
  validates :designation, presence: true
  validates :join_date, presence: true
end
