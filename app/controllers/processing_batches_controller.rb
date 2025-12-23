class ProcessingBatchesController < ApplicationController
  before_action :set_processing_batch, only: %i[show]

  def index
    @processing_batches = ProcessingBatch.order(created_at: :desc).limit(50)
  end

  def new
    @processing_batch = ProcessingBatch.new
  end

  def create
    @processing_batch = ProcessingBatch.new(processing_batch_params)
    if @processing_batch.save
      redirect_to @processing_batch, notice: 'Processing batch created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private

  def set_processing_batch
    @processing_batch = ProcessingBatch.find(params[:id])
  end

  def processing_batch_params
    params.require(:processing_batch).permit(:input_product_id, :input_jute_stock_id, :output_product_id, :input_quantity, :output_quantity, :waste_quantity, :cost, :processed_date)
  end
end
