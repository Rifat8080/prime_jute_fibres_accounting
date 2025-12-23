class StockMovementsController < ApplicationController
  before_action :set_stock_movement, only: [ :show, :edit, :update, :destroy ]

  def index
    conn = ActiveRecord::Base.connection
    order_col = (conn.respond_to?(:column_exists?) && conn.column_exists?(:stock_movements, :movement_date)) ? "movement_date" : "created_at"
    @stock_movements = StockMovement.order(Arel.sql("#{order_col} DESC"))
  end

  def show
  end

  def new
    @stock_movement = StockMovement.new
    if params[:jute_stock_id].present?
      js = JuteStock.find_by(id: params[:jute_stock_id])
      if js
        if ActiveRecord::Base.connection.column_exists?(:stock_movements, :jute_stock_id)
          @stock_movement.jute_stock_id = js.id
        else
          @stock_movement.product_id = js.product_id if js.respond_to?(:product_id)
          # stock_house_id on JuteStock maps to warehouse_id on StockMovement in this schema
          @stock_movement.warehouse_id = js.stock_house_id if js.respond_to?(:stock_house_id)
        end
      end
    end
  end

  def edit
  end

  def create
    @stock_movement = StockMovement.new(stock_movement_params)

    if @stock_movement.save
      redirect_to stock_movements_path, notice: "Stock movement was successfully created."
    else
      flash.now[:alert] = @stock_movement.errors.full_messages.join("; ")
      render :new
    end
  end

  def update
    if @stock_movement.update(stock_movement_params)
      redirect_to stock_movements_path, notice: "Stock movement was successfully updated."
    else
      flash.now[:alert] = @stock_movement.errors.full_messages.join("; ")
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
    params.require(:stock_movement).permit(:jute_stock_id, :product_id, :warehouse_id, :source_type, :source_id, :movement_type, :quantity_bales, :quantity, :movement_date, :notes)
  end
end
# StockMovements feature removed.
# File left intentionally blank to avoid accidental usage. See commit removing stock movements.
