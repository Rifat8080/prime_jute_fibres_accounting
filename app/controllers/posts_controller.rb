class PostsController < ApplicationController
  before_action :authenticate_user!, only: [ :dashboard ]

  def index
    # Always render the public landing page at root, even when signed in.
  end

  def dashboard
    @supplier_count = Supplier.count
    @stock_house_count = StockHouse.count
    @product_count = Product.count
    @total_jute_stock = JuteStock.sum(:quantity) || 0
    @pending_shipments = Shipment.where(status: ["pending", "draft"]).count
    @cash_balance = Account.cash_accounts.sum(:current_balance)
    @receivables_balance = Account.receivables.sum(:current_balance)
    @payables_balance = Account.payables.sum(:current_balance)
    @total_account_balance = Account.sum(:current_balance)
    @total_revenue = Transaction.credits.where(category: "revenue").sum(:amount)
    @total_expense = Transaction.debits.where(category: "expense").sum(:amount)
    @net_profit = @total_revenue - @total_expense
    @recent_transactions = Transaction.recent.limit(5)
    render :dashboard, layout: "authenticated"
  end
end
