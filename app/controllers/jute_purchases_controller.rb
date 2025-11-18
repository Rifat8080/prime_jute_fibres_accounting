class JutePurchasesController < ApplicationController
  before_action :set_jute_purchase, only: [:show, :edit, :update, :destroy]

  # GET /jute_purchases
  def index
    @jute_purchases = JutePurchase.all
  end

  # GET /jute_purchases/1
  def show
  end

  # GET /jute_purchases/new
  def new
    @jute_purchase = JutePurchase.new
  end

  # GET /jute_purchases/1/edit
  def edit
  end

  # POST /jute_purchases
  def create
    @jute_purchase = JutePurchase.new(jute_purchase_params)

    if @jute_purchase.save
      redirect_to @jute_purchase, notice: 'Jute purchase was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /jute_purchases/1
  def update
    if @jute_purchase.update(jute_purchase_params)
      redirect_to @jute_purchase, notice: 'Jute purchase was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /jute_purchases/1
  def destroy
    @jute_purchase.destroy
    redirect_to jute_purchases_url, notice: 'Jute purchase was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_jute_purchase
      @jute_purchase = JutePurchase.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def jute_purchase_params
      params.require(:jute_purchase).permit(:supplier_id, :purchase_date, :jute_variety, :quantity_kg, :rate_per_kg, :total_amount, :notes)
    end
end
