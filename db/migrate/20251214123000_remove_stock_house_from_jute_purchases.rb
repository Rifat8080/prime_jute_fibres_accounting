class RemoveStockHouseFromJutePurchases < ActiveRecord::Migration[8.0]
  def change
    remove_reference :jute_purchases, :stock_house, type: :uuid, foreign_key: true, index: true
  end
end
