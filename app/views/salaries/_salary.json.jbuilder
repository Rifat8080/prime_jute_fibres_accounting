json.extract! salary, :id, :user_id, :payment_date, :amount, :payment_period_start, :payment_period_end, :notes, :created_at, :updated_at
json.url salary_url(salary, format: :json)
