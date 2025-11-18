class CreateShipmentDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :shipment_documents, id: :uuid do |t|
      t.references :shipment, null: false, foreign_key: true, type: :uuid
      t.string :document_type
      t.text :notes

      t.timestamps
    end
  end
end
