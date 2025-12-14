class AddTransactionDetailsToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :bank, :string
    add_column :transactions, :transaction_reference, :string
    add_column :transactions, :beneficiary, :string
  end
end
