class AddProductToJutePurchases < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:jute_purchases, :product_id)
      add_column :jute_purchases, :product_id, :uuid
      add_index :jute_purchases, :product_id
    end
  end
end
