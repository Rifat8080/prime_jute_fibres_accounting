class EnsureProcurementCostsTable < ActiveRecord::Migration[8.0]
  def change
    return if table_exists?(:procurement_costs)

    create_table :procurement_costs, id: :uuid do |t|
      t.references :costable, polymorphic: true, null: false, type: :uuid
      t.string :cost_type
      t.decimal :amount, precision: 15, scale: 2
      t.date :cost_date
      t.text :description

      t.timestamps
    end
  end
end
