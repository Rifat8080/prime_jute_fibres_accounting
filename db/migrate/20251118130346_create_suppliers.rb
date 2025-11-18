class CreateSuppliers < ActiveRecord::Migration[8.0]
  def change
    create_table :suppliers, id: :uuid do |t|
      t.string :name
      t.string :contact_person
      t.string :phone
      t.text :address
      t.string :supplier_type

      t.timestamps
    end
  end
end
