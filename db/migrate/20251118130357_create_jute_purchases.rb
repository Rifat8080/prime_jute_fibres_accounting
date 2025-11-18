class CreateJutePurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :jute_purchases, id: :uuid do |t|
      t.references :supplier, null: false, foreign_key: true, type: :uuid
      t.date :purchase_date
      t.string :jute_variety
      t.decimal :quantity_kg
      t.decimal :rate_per_kg
      t.decimal :total_amount
      t.text :notes

      t.timestamps
    end
  end
end
