class CreateSalaries < ActiveRecord::Migration[8.0]
  def change
    create_table :salaries, id: :uuid do |t|
      t.references :employee, null: false, foreign_key: true, type: :uuid
      t.date :payment_date
      t.decimal :amount
      t.date :payment_period_start
      t.date :payment_period_end
      t.text :notes

      t.timestamps
    end
  end
end
