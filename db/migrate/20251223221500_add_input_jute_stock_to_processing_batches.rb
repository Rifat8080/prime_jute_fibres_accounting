class AddInputJuteStockToProcessingBatches < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:processing_batches, :input_jute_stock_id)
      add_column :processing_batches, :input_jute_stock_id, :uuid
      add_index :processing_batches, :input_jute_stock_id
    end
  end
end
