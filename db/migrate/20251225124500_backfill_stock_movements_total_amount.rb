class BackfillStockMovementsTotalAmount < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    say_with_time "Backfilling stock_movements.total_amount from jute_purchases" do
      StockMovement.where(reference_type: 'JutePurchase').where(total_amount: nil).find_each do |sm|
        jp = JutePurchase.find_by(id: sm.reference_id)
        if jp && jp.total_amount.present?
          sm.update_columns(total_amount: jp.total_amount)
        end
      end
    end
  end

  def down
    # no-op
  end
end
