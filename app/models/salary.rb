class Salary < ApplicationRecord
  belongs_to :user

  after_create :post_accounting_transaction

  def post_accounting_transaction
    expense_account = Account.find_or_create_by!(name: "Salary Expense", account_type: "expense", account_number: "3000", bank_name: "Internal")
    cash_account = Account.cash_accounts.first || Account.find_or_create_by!(name: "Cash", account_type: "cash", account_number: "2000", bank_name: "Prime Bank")

    Transaction.post!(
      debit_account: expense_account,
      credit_account: cash_account,
      amount: amount,
      transaction_date: payment_date,
      description: "Salary payment to #{user&.name} for #{payment_period_start} - #{payment_period_end}",
      category: "expense",
      related_entity: self
    )
  end
end
