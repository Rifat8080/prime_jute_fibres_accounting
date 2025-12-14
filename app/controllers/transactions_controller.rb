class TransactionsController < ApplicationController
  before_action :set_account
  before_action :set_transaction, only: [ :show, :edit, :update, :destroy ]

  # GET /transactions
  def index
    @transactions = @account.transactions
  end

  # GET /transactions/1
  def show
  end

  # GET /transactions/new
  def new
    @transaction = @account.transactions.new
  end

  # GET /transactions/1/edit
  def edit
  end

  # POST /transactions
  def create
    # protect against invalid polymorphic type input (e.g. user typed 'jn')
    tparams = transaction_params.to_h
    if tparams["related_entity_type"].present? && tparams["related_entity_type"].safe_constantize.nil?
      @transaction = @account.transactions.new(tparams.except("related_entity_type", "related_entity_id"))
      @transaction.errors.add(:related_entity_type, "is invalid")
      render :new and return
    end

    @transaction = @account.transactions.new(tparams)
    # Ensure polymorphic related fields satisfy DB NOT NULL constraints.
    # Transactions are scoped to an Account now, so use the account as the related entity.
    @transaction.related_entity_type ||= "Account"
    @transaction.related_entity_id ||= @account.id

    if @transaction.save
      redirect_to [ @account, @transaction ], notice: "Transaction was successfully created."
    else
      render :new
    end
  end

  # PATCH/PUT /transactions/1
  def update
    tparams = transaction_params.to_h
    if tparams["related_entity_type"].present? && tparams["related_entity_type"].safe_constantize.nil?
      @transaction.errors.add(:related_entity_type, "is invalid")
      render :edit and return
    end

    if @transaction.update(tparams)
      redirect_to [ @account, @transaction ], notice: "Transaction was successfully updated."
    else
      render :edit
    end
  end

  # DELETE /transactions/1
  def destroy
    @transaction.destroy
    redirect_to account_transactions_url(@account), notice: "Transaction was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
        @transaction = @account.transactions.find(params[:id])
    end

      def set_account
        @account = Account.find(params[:account_id])
      end

    # Only allow a list of trusted parameters through.
    def transaction_params
      params.require(:transaction).permit(:transaction_type, :transaction_reference, :beneficiary, :amount)
    end
end
