class CreateSalesContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :sales_contracts, id: :uuid do |t|
      t.references :buyer, null: false, foreign_key: true, type: :uuid
      t.string :contract_type
      t.string :contract_number
      t.date :contract_date
      t.jsonb :details

      t.timestamps
    end
    add_index :sales_contracts, :contract_number, unique: true
  end
end
