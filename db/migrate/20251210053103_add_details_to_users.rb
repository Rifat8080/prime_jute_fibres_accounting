class AddDetailsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :phone, :string
    add_column :users, :designation, :string
    add_column :users, :role, :string
  end
end
