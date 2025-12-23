class RenameSalesOrdersToSalesContracts < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    if table_exists?(:sales_orders) && !table_exists?(:sales_contracts)
      rename_table :sales_orders, :sales_contracts

      if column_exists?(:sales_contracts, :order_date) && !column_exists?(:sales_contracts, :contract_date)
        rename_column :sales_contracts, :order_date, :contract_date
      end

      if column_exists?(:sales_contracts, :sale_type) && !column_exists?(:sales_contracts, :contract_type)
        rename_column :sales_contracts, :sale_type, :contract_type
      end

      unless column_exists?(:sales_contracts, :contract_number)
        add_column :sales_contracts, :contract_number, :string
      end

      unless column_exists?(:sales_contracts, :details)
        add_column :sales_contracts, :details, :jsonb, default: {}
      end

      # Backfill contract_number for existing rows
      reversible do |dir|
        dir.up do
          say_with_time "Backfilling contract_number for existing sales_contracts" do
            execute <<~SQL.squish
              UPDATE sales_contracts
              SET contract_number = ('SC-' || substr(id::text, 1, 8))
              WHERE contract_number IS NULL
            SQL
          end
        end
      end

      # Add index for uniqueness
      unless index_exists?(:sales_contracts, :contract_number, unique: true)
        add_index :sales_contracts, :contract_number, unique: true
      end
    end
  end

  def down
    if table_exists?(:sales_contracts) && !table_exists?(:sales_orders)
      if index_exists?(:sales_contracts, :contract_number, unique: true)
        remove_index :sales_contracts, :contract_number
      end

      if column_exists?(:sales_contracts, :details)
        remove_column :sales_contracts, :details
      end

      if column_exists?(:sales_contracts, :contract_number)
        remove_column :sales_contracts, :contract_number
      end

      if column_exists?(:sales_contracts, :contract_type) && !column_exists?(:sales_contracts, :sale_type)
        rename_column :sales_contracts, :contract_type, :sale_type
      end

      if column_exists?(:sales_contracts, :contract_date) && !column_exists?(:sales_contracts, :order_date)
        rename_column :sales_contracts, :contract_date, :order_date
      end

      rename_table :sales_contracts, :sales_orders
    end
  end
end
