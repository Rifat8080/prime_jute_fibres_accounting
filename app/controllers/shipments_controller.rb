class ShipmentsController < ApplicationController
  before_action :set_shipment, only: [:show, :edit, :update, :destroy]

  # GET /shipments
  def index
    @shipments = Shipment.all
  end

  # GET /shipments/1
  def show
  end

  # GET /shipments/new
  def new
    @shipment = Shipment.new
  end

  # GET /shipments/1/edit
  def edit
  end

  # POST /shipments
  def create
    @shipment = Shipment.new(shipment_params)

    if @shipment.save
      redirect_to @shipment, notice: 'Shipment was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /shipments/1
  def update
    if @shipment.update(shipment_params)
      redirect_to @shipment, notice: 'Shipment was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /shipments/1
  def destroy
    @shipment.destroy
    redirect_to shipments_url, notice: 'Shipment was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shipment
      @shipment = Shipment.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def shipment_params
      params.require(:shipment).permit(:sales_contract_id, :stock_house_id, :jute_quality, :shipment_date, :invoice_number, :total_bales, :total_value, :destination_port, :status)
    end
end
