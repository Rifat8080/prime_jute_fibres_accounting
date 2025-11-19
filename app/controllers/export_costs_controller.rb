class ExportCostsController < ApplicationController
  before_action :set_export_cost, only: [:show, :edit, :update, :destroy]

  # GET /export_costs
  def index
    @export_costs = ExportCost.all
  end

  # GET /export_costs/1
  def show
  end

  # GET /export_costs/new
  def new
    @export_cost = ExportCost.new
  end

  # GET /export_costs/1/edit
  def edit
  end

  # POST /export_costs
  def create
    @export_cost = ExportCost.new(export_cost_params)

    if @export_cost.save
      redirect_to @export_cost, notice: 'Export cost was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /export_costs/1
  def update
    if @export_cost.update(export_cost_params)
      redirect_to @export_cost, notice: 'Export cost was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /export_costs/1
  def destroy
    @export_cost.destroy
    redirect_to export_costs_url, notice: 'Export cost was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_export_cost
      @export_cost = ExportCost.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def export_cost_params
      params.require(:export_cost).permit(:shipment_id, :cost_type, :amount, :description)
    end
end
