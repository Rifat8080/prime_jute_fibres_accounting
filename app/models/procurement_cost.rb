class ProcurementCost < ApplicationRecord
  belongs_to :costable, polymorphic: true

  validates :cost_type, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :cost_date, presence: true
  validates :costable, presence: true
  validates :costable_type, inclusion: { in: [ "JutePurchase", "ProcessingBatch" ] }

  after_save :update_costable_total_amount
  after_destroy :update_costable_total_amount
  after_create :post_accounting_transaction

  private

  def update_costable_total_amount
    if costable.is_a?(JutePurchase)
      costable.save # This will trigger the before_save callback in JutePurchase
    end
  end

  def post_accounting_transaction
    return if costable.is_a?(JutePurchase) # Already handled in JutePurchase transaction

    if costable.is_a?(ProcessingBatch)
      expense_account = Account.find_or_create_by!(name: "Processing Expense", account_type: "expense", account_number: "4000", bank_name: "Internal")
      cash_account = Account.cash_accounts.first || Account.find_or_create_by!(name: "Cash", account_type: "cash", account_number: "2000", bank_name: "Prime Bank")

      Transaction.post!(
        debit_account: expense_account,
        credit_account: cash_account,
        amount: amount,
        transaction_date: cost_date,
        description: "#{cost_type} cost for processing batch #{costable&.batch_no}",
        category: "expense",
        related_entity: self
      )
    end
  end
end
