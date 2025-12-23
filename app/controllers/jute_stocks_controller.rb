class JuteStocksController < ApplicationController
  before_action :set_jute_stock, only: [ :show, :edit, :update, :destroy ]

  # GET /jute_stocks
  def index
    @jute_stocks = JuteStock.all
  end

  # GET /jute_stocks/1
  def show
  end

  # GET /jute_stocks/new
  def new
    @jute_stock = JuteStock.new
  end

  # GET /jute_stocks/1/edit
  def edit
  end

  # POST /jute_stocks
  def create
    @jute_stock = JuteStock.new(jute_stock_params)

    if @jute_stock.save
      redirect_to @jute_stock, notice: "Jute stock was successfully created."
    else
      render :new
    end
  end

  # PATCH/PUT /jute_stocks/1
  def update
    if @jute_stock.update(jute_stock_params)
      redirect_to @jute_stock, notice: "Jute stock was successfully updated."
    else
      render :edit
    end
  end

  # DELETE /jute_stocks/1
  def destroy
    @jute_stock.destroy
    redirect_to jute_stocks_url, notice: "Jute stock was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_jute_stock
      @jute_stock = JuteStock.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def jute_stock_params
      params.require(:jute_stock).permit(:stock_house_id, :jute_quality, :quantity, :last_updated)
    end
end
