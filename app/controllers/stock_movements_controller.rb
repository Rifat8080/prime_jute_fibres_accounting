class StockMovementsController < ApplicationController
  before_action :set_stock_movement, only: [ :show, :edit, :update, :destroy ]

  def index
    @stock_movements = StockMovement.order(movement_date: :desc)
  end

  def show
  end

  def new
    @stock_movement = StockMovement.new(jute_stock_id: params[:jute_stock_id])
  end

  def edit
  end

  def create
    @stock_movement = StockMovement.new(stock_movement_params)

    if @stock_movement.save
      redirect_to stock_movements_path, notice: "Stock movement was successfully created."
    else
      render :new
    end
  end

  def update
    if @stock_movement.update(stock_movement_params)
      redirect_to stock_movements_path, notice: "Stock movement was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @stock_movement.destroy
    redirect_to stock_movements_path, notice: "Stock movement was successfully destroyed."
  end

  private

  def set_stock_movement
    @stock_movement = StockMovement.find(params[:id])
  end

  def stock_movement_params
    params.require(:stock_movement).permit(:jute_stock_id, :source_type, :source_id, :movement_type, :quantity_bales, :movement_date, :notes)
  end
end
# StockMovements feature removed.
# File left intentionally blank to avoid accidental usage. See commit removing stock movements.
