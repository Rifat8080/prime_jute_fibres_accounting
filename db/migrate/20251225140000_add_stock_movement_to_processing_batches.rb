class AddStockMovementToProcessingBatches < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:processing_batches, :stock_movement_id)
      add_reference :processing_batches, :stock_movement, type: :uuid, index: true, foreign_key: false
    end
  end
end
