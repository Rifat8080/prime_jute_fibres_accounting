class DropExportCosts < ActiveRecord::Migration[7.1]
  def change
    drop_table :export_costs
  end
end