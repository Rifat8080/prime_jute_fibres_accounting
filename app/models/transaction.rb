class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :related_entity, polymorphic: true, optional: true

  TRANSACTION_TYPES = %w[debit credit].freeze

  validates :transaction_date, presence: true
  validates :transaction_type, presence: true, inclusion: { in: TRANSACTION_TYPES, message: "%{value} is not a valid type" }
  validates :amount, presence: true, numericality: { greater_than: 0 }

  scope :debits, -> { where(transaction_type: "debit") }
  scope :credits, -> { where(transaction_type: "credit") }
  scope :recent, -> { order(transaction_date: :desc, created_at: :desc) }
  scope :for_account, ->(account_ids) { where(account_id: account_ids) }

  before_validation :set_default_transaction_date
  before_validation :normalize_transaction_type

  after_create :apply_to_account
  before_update :cache_previous_values
  after_update :apply_update_to_account
  after_destroy :revert_from_account

  def self.post!(debit_account:, credit_account:, amount:, transaction_date: Time.zone.today, description: nil, category: nil, related_entity: nil, transaction_reference: nil, beneficiary: nil)
    amount = amount.to_d
    raise ArgumentError, "Amount must be positive" if amount <= 0

    transaction_date ||= Time.zone.today

    ActiveRecord::Base.transaction do
      debit = create!(
        account: debit_account,
        related_entity: related_entity,
        transaction_date: transaction_date,
        transaction_type: "debit",
        amount: amount,
        description: description,
        category: category,
        transaction_reference: transaction_reference,
        beneficiary: beneficiary
      )

      credit = create!(
        account: credit_account,
        related_entity: related_entity,
        transaction_date: transaction_date,
        transaction_type: "credit",
        amount: amount,
        description: description,
        category: category,
        transaction_reference: transaction_reference,
        beneficiary: beneficiary
      )

      [debit, credit]
    end
  end

  def credit?
    transaction_type.to_s.downcase == "credit"
  end

  def debit?
    transaction_type.to_s.downcase == "debit"
  end

  private

  def set_default_transaction_date
    self.transaction_date ||= Time.zone.current.to_date
  end

  def normalize_transaction_type
    self.transaction_type = transaction_type.to_s.downcase if transaction_type.present?
  end

  def apply_to_account
    delta = effect_amount
    adjust_account_balance!(delta)
  end

  def cache_previous_values
    @previous_amount = amount_was || 0
    @previous_type = transaction_type_was
  end

  def apply_update_to_account
    previous_effect = effect_for(@previous_type, @previous_amount)
    new_effect = effect_amount
    delta = new_effect - previous_effect
    adjust_account_balance!(delta)
  end

  def revert_from_account
    # revert by subtracting this transaction's effect
    delta = -effect_amount
    adjust_account_balance!(delta)
  end

  def effect_amount
    effect_for(transaction_type, amount || 0)
  end

  def effect_for(type, amt)
    return 0 unless amt
    case type.to_s.downcase
    when "credit"
      BigDecimal(amt.to_s)
    when "debit"
      -BigDecimal(amt.to_s)
    else
      # default: treat as credit
      BigDecimal(amt.to_s)
    end
  end

  def adjust_account_balance!(delta)
    return unless account
    account.with_lock do
      current = account.current_balance || 0
      new_balance = BigDecimal(current.to_s) + BigDecimal(delta.to_s)
      # use update_column to avoid triggering validations that may prevent negative balances
      account.update_column(:current_balance, new_balance)
    end
  end
end
