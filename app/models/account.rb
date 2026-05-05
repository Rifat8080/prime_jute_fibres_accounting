class Account < ApplicationRecord
  has_many :transactions, dependent: :destroy
  belongs_to :parent, class_name: "Account", optional: true
  has_many :children, class_name: "Account", foreign_key: :parent_id, dependent: :nullify

  ACCOUNT_TYPES = %w[cash bank receivable payable expense revenue asset liability equity].freeze

  validates :name, presence: true
  validates :account_type, presence: true, inclusion: { in: ACCOUNT_TYPES }
  validates :account_number, presence: true, uniqueness: true
  validates :bank_name, presence: true
  validates :current_balance, presence: true, numericality: true

  before_validation :ensure_current_balance

  scope :cash_accounts, -> { where(account_type: %w[cash bank]) }
  scope :receivables, -> { where(account_type: "receivable") }
  scope :payables, -> { where(account_type: "payable") }
  scope :expense_accounts, -> { where(account_type: "expense") }
  scope :revenue_accounts, -> { where(account_type: "revenue") }

  def ensure_current_balance
    self.current_balance ||= 0
  end

  def debit_total
    transactions.debits.sum(:amount)
  end

  def credit_total
    transactions.credits.sum(:amount)
  end

  def transaction_balance
    result = transactions.sum(
      "CASE WHEN transaction_type = 'credit' THEN amount ELSE -amount END"
    )
    result.to_d
  end

  def recalculate_balance!
    update!(current_balance: transaction_balance)
  end
end
