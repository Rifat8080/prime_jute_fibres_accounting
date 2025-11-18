class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :related_entity, polymorphic: true, null: false, type: :uuid
      t.datetime :transaction_date
      t.string :transaction_type
      t.decimal :amount
      t.text :description
      t.string :category

      t.timestamps
    end
  end
end
