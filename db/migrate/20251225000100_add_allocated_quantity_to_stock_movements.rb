class AddAllocatedQuantityToStockMovements < ActiveRecord::Migration[7.0]
  def change
    add_column :stock_movements, :allocated_quantity, :decimal, precision: 16, scale: 3, default: "0", null: false
  end
end
