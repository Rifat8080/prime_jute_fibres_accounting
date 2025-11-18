class CreateStockHouses < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_houses, id: :uuid do |t|
      t.string :name
      t.string :location

      t.timestamps
    end
  end
end
