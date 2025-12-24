class RemoveJutePurchaseFromProcessingBatches < ActiveRecord::Migration[6.1]
  def change
    remove_reference :processing_batches, :jute_purchase, type: :uuid, foreign_key: true
  end
end
