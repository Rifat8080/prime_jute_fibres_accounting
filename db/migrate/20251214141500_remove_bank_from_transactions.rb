class RemoveBankFromTransactions < ActiveRecord::Migration[8.0]
  def change
    remove_column :transactions, :bank, :string
  end
end
