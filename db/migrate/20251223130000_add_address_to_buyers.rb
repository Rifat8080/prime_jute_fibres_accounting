class AddAddressToBuyers < ActiveRecord::Migration[8.0]
  def up
    unless column_exists?(:buyers, :address)
      add_column :buyers, :address, :text
    end
  end

  def down
    if column_exists?(:buyers, :address)
      remove_column :buyers, :address
    end
  end
end
