class AddStockHouseIdBackToJutePurchases < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:jute_purchases, :stock_house_id)
      add_column :jute_purchases, :stock_house_id, :uuid
      add_index :jute_purchases, :stock_house_id
      if table_exists?(:stock_houses)
        add_foreign_key :jute_purchases, :stock_houses, column: :stock_house_id
      end
    end
  end
end
