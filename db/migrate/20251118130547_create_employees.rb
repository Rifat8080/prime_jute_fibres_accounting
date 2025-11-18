class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees, id: :uuid do |t|
      t.string :name
      t.string :employee_type
      t.string :designation
      t.date :join_date
      t.string :phone

      t.timestamps
    end
  end
end
