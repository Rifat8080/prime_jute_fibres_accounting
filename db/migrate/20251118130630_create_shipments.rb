class CreateShipments < ActiveRecord::Migration[8.0]
  def change
    create_table :shipments, id: :uuid do |t|
      t.references :sales_contract, null: false, foreign_key: true, type: :uuid
      t.date :shipment_date
      t.string :invoice_number
      t.integer :total_bales
      t.decimal :total_value
      t.string :destination_port
      t.string :status

      t.timestamps
    end
  end
end
