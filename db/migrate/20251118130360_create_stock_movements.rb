class CreateStockMovements < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_movements, id: :uuid do |t|
      t.references :jute_stock, null: false, foreign_key: true, type: :uuid
      t.references :source, polymorphic: true, null: false, type: :uuid
      t.string :movement_type
      t.decimal :quantity_bales
      t.datetime :movement_date
      t.text :notes

      t.timestamps
    end
  end
end
