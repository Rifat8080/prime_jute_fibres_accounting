class AddMissingColumnsToJutePurchases < ActiveRecord::Migration[8.0]
  def up
    change_table :jute_purchases do |t|
      unless column_exists?(:jute_purchases, :jute_variety)
        t.string :jute_variety
      end

      unless column_exists?(:jute_purchases, :quantity_kg)
        t.decimal :quantity_kg, precision: 15, scale: 3
      end

      unless column_exists?(:jute_purchases, :rate_per_kg)
        t.decimal :rate_per_kg, precision: 15, scale: 3
      end

      unless column_exists?(:jute_purchases, :total_amount)
        if column_exists?(:jute_purchases, :total_cost)
          rename_column :jute_purchases, :total_cost, :total_amount
        else
          t.decimal :total_amount, precision: 15, scale: 2
        end
      end

      unless column_exists?(:jute_purchases, :notes)
        t.text :notes
      end
    end
  end

  def down
    change_table :jute_purchases do |t|
      if column_exists?(:jute_purchases, :notes)
        remove_column :jute_purchases, :notes
      end

      if column_exists?(:jute_purchases, :total_amount)
        if !column_exists?(:jute_purchases, :total_cost)
          # try to restore original name if we had renamed it
          begin
            rename_column :jute_purchases, :total_amount, :total_cost
          rescue StandardError
            t.remove :total_amount
          end
        else
          t.remove :total_amount
        end
      end

      t.remove :rate_per_kg if column_exists?(:jute_purchases, :rate_per_kg)
      t.remove :quantity_kg if column_exists?(:jute_purchases, :quantity_kg)
      t.remove :jute_variety if column_exists?(:jute_purchases, :jute_variety)
    end
  end
end
