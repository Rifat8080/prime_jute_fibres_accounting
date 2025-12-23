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
      redirect_to @processing_batch, notice: "Processing batch created successfully."
    else
      flash.now[:alert] = @processing_batch.errors.full_messages.join("; ")
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    @processing_batch ||= ProcessingBatch.new(processing_batch_params)
    @processing_batch.errors.add(:base, e.message)
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
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
