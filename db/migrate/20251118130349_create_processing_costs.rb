class CreateProcessingCosts < ActiveRecord::Migration[8.0]
  def change
    create_table :processing_costs, id: :uuid do |t|
      t.string :cost_type
      t.decimal :cost_per_unit
      t.string :unit_type
      t.date :effective_date

      t.timestamps
    end
  end
end
