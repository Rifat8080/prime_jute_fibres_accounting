class CreateJuteStocks < ActiveRecord::Migration[8.0]
  def change
    create_table :jute_stocks, id: :uuid do |t|
      t.references :stock_house, null: false, foreign_key: true, type: :uuid
      t.string :jute_quality
      t.decimal :quantity_bales
      t.datetime :last_updated

      t.timestamps
    end
  end
end
