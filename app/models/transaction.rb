class Transaction < ApplicationRecord
  belongs_to :account


  validates :transaction_type, presence: true, inclusion: { in: %w[debit credit], message: "%{value} is not a valid type" }
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_create :apply_to_account
  before_update :cache_previous_values
  after_update :apply_update_to_account
  after_destroy :revert_from_account

  def credit?
    transaction_type.to_s.downcase == "credit"
  end

  def debit?
    transaction_type.to_s.downcase == "debit"
  end

  private

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
