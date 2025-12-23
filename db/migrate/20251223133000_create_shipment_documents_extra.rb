class CreateShipmentDocumentsExtra < ActiveRecord::Migration[8.0]
  def change
    # no-op duplicate moved to a different migration name to avoid conflicts
    nil if table_exists?(:shipment_documents)
  end
end
