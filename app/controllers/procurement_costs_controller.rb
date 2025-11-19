class ProcurementCostsController < ApplicationController
  before_action :set_procurement_cost, only: [:show, :edit, :update, :destroy]

  # GET /procurement_costs
  def index
    @procurement_costs = ProcurementCost.all
  end

  # GET /procurement_costs/1
  def show
  end

  # GET /procurement_costs/new
  def new
    @procurement_cost = ProcurementCost.new
    if params[:costable_id] && params[:costable_type]
      @procurement_cost.costable_id = params[:costable_id]
      @procurement_cost.costable_type = params[:costable_type]
    end
  end

  # GET /procurement_costs/1/edit
  def edit
  end

  # POST /procurement_costs
  def create
    @procurement_cost = ProcurementCost.new(procurement_cost_params)

    if @procurement_cost.save
      if @procurement_cost.costable
        redirect_to @procurement_cost.costable, notice: 'Procurement cost was successfully created.'
      else
        redirect_to @procurement_cost, notice: 'Procurement cost was successfully created.'
      end
    else
      render :new
    end
  end

  # PATCH/PUT /procurement_costs/1
  def update
    if @procurement_cost.update(procurement_cost_params)
      redirect_to @procurement_cost, notice: 'Procurement cost was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /procurement_costs/1
  def destroy
    @procurement_cost.destroy
    redirect_to procurement_costs_url, notice: 'Procurement cost was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_procurement_cost
      @procurement_cost = ProcurementCost.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def procurement_cost_params
      params.require(:procurement_cost).permit(:cost_type, :amount, :cost_date, :description, :costable_id, :costable_type)
    end
end
