# Backfill stock_movements.total_amount from related JutePurchase.total_amount
cnt = 0
StockMovement.where(reference_type: 'JutePurchase').where(total_amount: nil).find_each do |sm|
  jp = JutePurchase.find_by(id: sm.reference_id)
  if jp && jp.total_amount.present?
    sm.update_columns(total_amount: jp.total_amount)
    cnt += 1
  end
end
puts "Updated #{cnt} stock_movements"
