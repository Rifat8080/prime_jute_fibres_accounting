class StockHousesController < ApplicationController
  before_action :set_stock_house, only: [ :show, :edit, :update, :destroy ]

  # GET /stock_houses
  def index
    @stock_houses = StockHouse.all
  end

  # GET /stock_houses/1
  def show
  end

  # GET /stock_houses/new
  def new
    @stock_house = StockHouse.new
    @redirect_to_jute_purchase = params[:redirect_to_jute_purchase]
  end

  # GET /stock_houses/1/edit
  def edit
  end

  # POST /stock_houses
  def create
    @stock_house = StockHouse.new(stock_house_params)

    respond_to do |format|
      if @stock_house.save
        format.html { redirect_to @stock_house, notice: "Stock house was successfully created." }
        format.json { render :show, status: :created, location: @stock_house }
        format.turbo_stream
      else
        format.html { render :new }
        format.json { render json: @stock_house.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /stock_houses/1
  def update
    if @stock_house.update(stock_house_params)
      redirect_to @stock_house, notice: "Stock house was successfully updated."
    else
      render :edit
    end
  end

  # DELETE /stock_houses/1
  def destroy
    @stock_house.destroy
    redirect_to stock_houses_url, notice: "Stock house was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_stock_house
      @stock_house = StockHouse.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def stock_house_params
      params.require(:stock_house).permit(:name, :location)
    end
end
