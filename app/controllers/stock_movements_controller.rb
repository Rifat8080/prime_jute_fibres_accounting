class StockMovementsController < ApplicationController
  before_action :set_stock_movement, only: [:show, :edit, :update, :destroy]

  # GET /stock_movements
  def index
    @stock_movements = StockMovement.all
  end

  # GET /stock_movements/1
  def show
  end

  # GET /stock_movements/new
  def new
    @stock_movement = StockMovement.new
  end

  # GET /stock_movements/1/edit
  def edit
  end

  # POST /stock_movements
  def create
    @stock_movement = StockMovement.new(stock_movement_params)

    if @stock_movement.save
      redirect_to @stock_movement, notice: 'Stock movement was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /stock_movements/1
  def update
    if @stock_movement.update(stock_movement_params)
      redirect_to @stock_movement, notice: 'Stock movement was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /stock_movements/1
  def destroy
    @stock_movement.destroy
    redirect_to stock_movements_url, notice: 'Stock movement was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_stock_movement
      @stock_movement = StockMovement.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def stock_movement_params
      params.require(:stock_movement).permit(:jute_stock_id, :source_id, :source_type, :movement_type, :quantity_bales, :movement_date, :notes)
    end
end
