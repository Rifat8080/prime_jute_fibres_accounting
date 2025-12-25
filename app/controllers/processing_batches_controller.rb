class ProcessingBatchesController < ApplicationController
  before_action :set_processing_batch, only: %i[show]
  before_action :set_jute_stock, only: %i[index new create]

  def index
    @processing_batches = if @jute_stock
                            @jute_stock.processing_batches.order(created_at: :desc)
                          else
                            ProcessingBatch.order(created_at: :desc).limit(50)
                          end
  end

  def new
    @processing_batch = ProcessingBatch.new
    if @jute_stock
      @processing_batch.input_product_id = @jute_stock.product_id if @jute_stock.respond_to?(:product_id)
      @processing_batch.processed_date = Date.today
    end
    # allow prefill from stock_movement show link
    if params[:input_product_id].present?
      @processing_batch.input_product_id ||= params[:input_product_id]
    end
    if params[:input_quantity].present?
      @processing_batch.input_quantity ||= params[:input_quantity]
    end
    if params[:processed_date].present?
      @processing_batch.processed_date ||= params[:processed_date]
    end
    if params[:stock_movement_id].present?
      @processing_batch.source_stock_movement_id = params[:stock_movement_id]
      @processing_batch.stock_movement_id = params[:stock_movement_id]
    end
    if params[:jute_stock_id].present?
      @processing_batch.source_jute_stock_id = params[:jute_stock_id]
      begin
        js = JuteStock.find_by(id: params[:jute_stock_id])
        @processing_batch._selected_input_stock = js if js
      rescue => _e
      end
    end
    # prebuild a few procurement_costs fields so the form can accept multiple costs
    (3 - @processing_batch.procurement_costs.size).times { @processing_batch.procurement_costs.build }
  end

  def create
    @processing_batch = ProcessingBatch.new(processing_batch_params)
    # accept a transient stock_movement reference indicating the source of input
    if params[:stock_movement_id].present?
      @processing_batch.source_stock_movement_id = params[:stock_movement_id]
      @processing_batch.stock_movement_id = params[:stock_movement_id]
    end
    if params[:jute_stock_id].present?
      @processing_batch.source_jute_stock_id = params[:jute_stock_id]
    end

    if @jute_stock
      @processing_batch.input_product_id ||= @jute_stock.product_id if @jute_stock.respond_to?(:product_id)
    end

    if @processing_batch.save
      redirect_target = @jute_stock ? jute_stock_processing_batches_path(@jute_stock) : @processing_batch
      redirect_to redirect_target, notice: "Processing batch created successfully."
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

  def set_jute_stock
    @jute_stock = JuteStock.find(params[:jute_stock_id]) if params[:jute_stock_id].present?
  end

  def processing_batch_params
    params.require(:processing_batch).permit(:input_product_id, :output_product_id, :input_quantity, :output_quantity, :waste_quantity, :cost, :processed_date,
      procurement_costs_attributes: [:id, :cost_type, :amount, :cost_date, :description, :_destroy])
  end
end
