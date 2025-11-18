class CreateExportCosts < ActiveRecord::Migration[8.0]
  def change
    create_table :export_costs, id: :uuid do |t|
      t.references :shipment, null: false, foreign_key: true, type: :uuid
      t.string :cost_type
      t.decimal :amount
      t.text :description

      t.timestamps
    end
  end
end
