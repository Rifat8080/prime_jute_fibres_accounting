class RemoveInputJuteStockFromProcessingBatches < ActiveRecord::Migration[8.0]
  def change
    if column_exists?(:processing_batches, :input_jute_stock_id)
      # Use remove_reference to also drop an fk if present
      remove_reference :processing_batches, :input_jute_stock, type: :uuid, foreign_key: false
      # Some schemas may have left an index; ensure it's removed
      if index_exists?(:processing_batches, :input_jute_stock_id)
        remove_index :processing_batches, :input_jute_stock_id
      end
    end
  end
end
