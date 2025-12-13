class DropEmployeesAndSalariesTables < ActiveRecord::Migration[8.0]
  def change
    drop_table :salaries
    drop_table :employees
  end
end
