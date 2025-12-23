class RenameLegacyTablesToAppTables < ActiveRecord::Migration[8.0]
  def up
    if table_exists?(:warehouses) && !table_exists?(:stock_houses)
      rename_table :warehouses, :stock_houses
    end

    if table_exists?(:inventories) && !table_exists?(:jute_stocks)
      rename_table :inventories, :jute_stocks
      if column_exists?(:jute_stocks, :warehouse_id) && !column_exists?(:jute_stocks, :stock_house_id)
        rename_column :jute_stocks, :warehouse_id, :stock_house_id
      end
    end

    if table_exists?(:purchases) && !table_exists?(:jute_purchases)
      rename_table :purchases, :jute_purchases
      if column_exists?(:jute_purchases, :warehouse_id) && !column_exists?(:jute_purchases, :stock_house_id)
        rename_column :jute_purchases, :warehouse_id, :stock_house_id
      end
    end
  end

  def down
    if table_exists?(:stock_houses) && !table_exists?(:warehouses)
      rename_table :stock_houses, :warehouses
    end

    if table_exists?(:jute_stocks) && !table_exists?(:inventories)
      if column_exists?(:jute_stocks, :stock_house_id) && !column_exists?(:jute_stocks, :warehouse_id)
        rename_column :jute_stocks, :stock_house_id, :warehouse_id
      end
      rename_table :jute_stocks, :inventories
    end

    if table_exists?(:jute_purchases) && !table_exists?(:purchases)
      if column_exists?(:jute_purchases, :stock_house_id) && !column_exists?(:jute_purchases, :warehouse_id)
        rename_column :jute_purchases, :stock_house_id, :warehouse_id
      end
      rename_table :jute_purchases, :purchases
    end
  end
end
