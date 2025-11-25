class SalesContractsController < ApplicationController
  before_action :set_sales_contract, only: [ :show, :edit, :update, :destroy ]

  # GET /sales_contracts
  def index
    @sales_contracts = SalesContract.all
  end

  # GET /sales_contracts/1
  def show
  end

  # GET /sales_contracts/new
  def new
    @sales_contract = SalesContract.new
  end

  # GET /sales_contracts/1/edit
  def edit
  end

  # POST /sales_contracts
  def create
    @sales_contract = SalesContract.new(sales_contract_params)

    if @sales_contract.save
      redirect_to @sales_contract, notice: "Sales contract was successfully created."
    else
      render :new
    end
  end

  # PATCH/PUT /sales_contracts/1
  def update
    if @sales_contract.update(sales_contract_params)
      redirect_to @sales_contract, notice: "Sales contract was successfully updated."
    else
      render :edit
    end
  end

  # DELETE /sales_contracts/1
  def destroy
    @sales_contract.destroy
    redirect_to sales_contracts_url, notice: "Sales contract was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sales_contract
      @sales_contract = SalesContract.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def sales_contract_params
      params.require(:sales_contract).permit(:buyer_id, :contract_type, :contract_number, :contract_date, :details)
    end
end
