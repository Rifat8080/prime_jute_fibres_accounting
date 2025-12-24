class AddJutePurchaseToProcessingBatches < ActiveRecord::Migration[6.1]
  def change
    add_reference :processing_batches, :jute_purchase, type: :uuid, foreign_key: true
  end
end
