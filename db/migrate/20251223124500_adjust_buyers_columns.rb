class AdjustBuyersColumns < ActiveRecord::Migration[8.0]
  def up
    if column_exists?(:buyers, :name) && !column_exists?(:buyers, :company_name)
      rename_column :buyers, :name, :company_name
    end

    change_table :buyers do |t|
      t.string :contact_person unless column_exists?(:buyers, :contact_person)
      t.string :email unless column_exists?(:buyers, :email)
      t.string :phone unless column_exists?(:buyers, :phone)
    end
  end

  def down
    change_table :buyers do |t|
      t.remove :phone if column_exists?(:buyers, :phone)
      t.remove :email if column_exists?(:buyers, :email)
      t.remove :contact_person if column_exists?(:buyers, :contact_person)
    end

    if column_exists?(:buyers, :company_name) && !column_exists?(:buyers, :name)
      rename_column :buyers, :company_name, :name
    end
  end
end
