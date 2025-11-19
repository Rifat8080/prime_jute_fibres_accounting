class AddJuteQualityAndStockHouseToShipments < ActiveRecord::Migration[8.0]
  def change
    add_column :shipments, :jute_quality, :string
    add_reference :shipments, :stock_house, type: :uuid, foreign_key: true
  end
end
