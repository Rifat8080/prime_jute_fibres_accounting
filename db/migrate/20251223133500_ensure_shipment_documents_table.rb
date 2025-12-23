class EnsureShipmentDocumentsTable < ActiveRecord::Migration[8.0]
  def up
    return if table_exists?(:shipment_documents)

    create_table :shipment_documents, id: :uuid do |t|
      t.uuid :shipment_id, null: false
      t.string :document_type
      t.text :notes

      t.timestamps
    end

    add_index :shipment_documents, :shipment_id
    add_foreign_key :shipment_documents, :shipments, column: :shipment_id
  end

  def down
    drop_table :shipment_documents if table_exists?(:shipment_documents)
  end
end
