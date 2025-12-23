namespace :data do
  desc "Fix JutePurchase.stock_house_id by inferring from related StockMovement or JuteStock"
  task fix_jute_purchase_stock_house: :environment do
    puts "Starting: fix_jute_purchase_stock_house"

    unless defined?(JutePurchase) && defined?(StockMovement) && defined?(JuteStock)
      puts "Required models not defined - aborting"
      next
    end

    total = 0
    updated = 0

    JutePurchase.find_each do |p|
      total += 1
      next if p.nil?

      next unless StockMovement.table_exists?

      mv = nil
      if StockMovement.column_names.include?("source_type") && StockMovement.column_names.include?("source_id")
        mv = StockMovement.where(source_type: "JutePurchase", source_id: p.id).order(:created_at).first
      elsif StockMovement.column_names.include?("reference_type") && StockMovement.column_names.include?("reference_id")
        mv = StockMovement.where(reference_type: "JutePurchase", reference_id: p.id).order(:created_at).first
      end

      house_id = nil
      if mv
        if mv.respond_to?(:warehouse_id) && mv.warehouse_id.present?
          house_id = mv.warehouse_id
        elsif mv.respond_to?(:jute_stock_id) && mv.jute_stock_id.present?
          js = JuteStock.find_by(id: mv.jute_stock_id)
          house_id = js&.stock_house_id
        elsif mv.jute_stock.present?
          house_id = mv.jute_stock.stock_house_id
        end
      end

      if house_id.present? && p.stock_house_id != house_id
        p.update_column(:stock_house_id, house_id)
        updated += 1
        puts "Updated JutePurchase id=#{p.id} -> stock_house_id=#{house_id}"
      end
    end

    puts "Done: processed=#{total}, updated=#{updated}"
  end
end
