class CreateBuyers < ActiveRecord::Migration[8.0]
  def change
    create_table :buyers, id: :uuid do |t|
      t.string :company_name
      t.string :contact_person
      t.string :email
      t.string :phone
      t.text :address
      t.string :country

      t.timestamps
    end
  end
end
