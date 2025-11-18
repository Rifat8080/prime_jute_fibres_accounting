class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts, id: :uuid do |t|
      t.string :name
      t.string :account_type
      t.string :account_number
      t.string :bank_name
      t.decimal :current_balance

      t.timestamps
    end
  end
end
