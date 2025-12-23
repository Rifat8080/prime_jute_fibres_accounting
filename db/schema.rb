# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_23_133500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "account_type"
    t.string "account_number"
    t.string "bank_name"
    t.decimal "current_balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "parent_id"
    t.string "code"
    t.integer "account_level", default: 0
    t.index ["code"], name: "index_accounts_on_code", unique: true
    t.index ["parent_id"], name: "index_accounts_on_parent_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "auditable_type"
    t.uuid "auditable_id"
    t.uuid "user_id"
    t.string "action"
    t.jsonb "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "bank_reconciliations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.date "period_start"
    t.date "period_end"
    t.boolean "reconciled", default: false
    t.uuid "reconciled_by"
    t.datetime "reconciled_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_bank_reconciliations_on_account_id"
  end

  create_table "buyers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "company_name"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "buyer_type"
    t.text "contact_details"
    t.string "contact_person"
    t.string "email"
    t.string "phone"
    t.text "address"
  end

  create_table "chart_of_accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code"
    t.string "name", null: false
    t.string "account_type"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_chart_of_accounts_on_code", unique: true
  end

  create_table "journal_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "posting_date", null: false
    t.string "description"
    t.string "source_type"
    t.uuid "source_id"
    t.jsonb "metadata", default: {}
    t.uuid "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "journal_id"
    t.index ["journal_id"], name: "index_journal_entries_on_journal_id"
    t.index ["source_type", "source_id"], name: "index_journal_entries_on_source_type_and_source_id"
  end

  create_table "journals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "journal_date"
    t.string "reference"
    t.text "description"
    t.boolean "posted", default: false, null: false
    t.uuid "posted_by"
    t.datetime "posted_at"
    t.uuid "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "jute_purchases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "supplier_id"
    t.date "purchase_date"
    t.string "reference_no"
    t.decimal "total_amount"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jute_variety"
    t.decimal "quantity_kg", precision: 15, scale: 3
    t.decimal "rate_per_kg", precision: 15, scale: 3
    t.text "notes"
    t.index ["supplier_id"], name: "index_jute_purchases_on_supplier_id"
  end

  create_table "jute_stocks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "product_id"
    t.uuid "stock_house_id"
    t.decimal "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_jute_stocks_on_product_id"
    t.index ["stock_house_id"], name: "index_jute_stocks_on_stock_house_id"
  end

  create_table "ledger_lines", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "journal_entry_id", null: false
    t.uuid "account_id"
    t.uuid "chart_of_account_id"
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.string "reference"
    t.string "related_entity_type"
    t.uuid "related_entity_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_ledger_lines_on_account_id"
    t.index ["journal_entry_id"], name: "index_ledger_lines_on_journal_entry_id"
    t.index ["related_entity_type", "related_entity_id"], name: "index_ledger_on_related"
  end

  create_table "loans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.decimal "principal", precision: 15, scale: 2, null: false
    t.decimal "interest_rate", precision: 8, scale: 5, null: false
    t.integer "tenure_months", null: false
    t.decimal "emi_amount", precision: 15, scale: 2
    t.decimal "outstanding_balance", precision: 15, scale: 2
    t.integer "installments_paid", default: 0
    t.date "start_date"
    t.date "next_due_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_loans_on_account_id"
  end

  create_table "processing_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "batch_no"
    t.date "processed_date"
    t.uuid "input_product_id"
    t.uuid "output_product_id"
    t.decimal "input_quantity"
    t.decimal "output_quantity"
    t.decimal "waste_quantity"
    t.decimal "cost"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["input_product_id"], name: "index_processing_batches_on_input_product_id"
    t.index ["output_product_id"], name: "index_processing_batches_on_output_product_id"
  end

  create_table "processing_costs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "cost_type"
    t.decimal "cost_per_unit"
    t.string "unit_type"
    t.date "effective_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "product_type"
    t.string "category"
    t.string "unit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "purchase_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "purchase_id"
    t.uuid "product_id"
    t.decimal "quantity"
    t.decimal "unit_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_items_on_product_id"
    t.index ["purchase_id"], name: "index_purchase_items_on_purchase_id"
  end

  create_table "reconciliation_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "bank_reconciliation_id", null: false
    t.uuid "journal_entry_id"
    t.string "source_type"
    t.uuid "source_id"
    t.decimal "amount", precision: 15, scale: 2
    t.boolean "matched", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_reconciliation_id"], name: "index_reconciliation_items_on_bank_reconciliation_id"
  end

  create_table "salaries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.date "payment_date"
    t.decimal "amount"
    t.date "payment_period_start"
    t.date "payment_period_end"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_salaries_on_user_id"
  end

  create_table "sales_contracts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "buyer_id"
    t.date "contract_date"
    t.string "contract_type"
    t.string "currency"
    t.decimal "total_amount"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "contract_number"
    t.jsonb "details", default: {}
    t.index ["buyer_id"], name: "index_sales_contracts_on_buyer_id"
    t.index ["contract_number"], name: "index_sales_contracts_on_contract_number", unique: true
  end

  create_table "sales_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "sales_order_id"
    t.uuid "product_id"
    t.decimal "quantity"
    t.decimal "unit_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_sales_items_on_product_id"
    t.index ["sales_order_id"], name: "index_sales_items_on_sales_order_id"
  end

  create_table "shipment_documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "shipment_id", null: false
    t.string "document_type"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shipment_id"], name: "index_shipment_documents_on_shipment_id"
  end

  create_table "shipments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "shipment_date"
    t.string "invoice_number"
    t.integer "total_bales"
    t.decimal "total_value"
    t.string "destination_port"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jute_quality"
    t.uuid "stock_house_id"
    t.uuid "sales_order_id"
    t.index ["sales_order_id"], name: "index_shipments_on_sales_order_id"
    t.index ["stock_house_id"], name: "index_shipments_on_stock_house_id"
  end

  create_table "stock_houses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stock_movements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "product_id"
    t.uuid "warehouse_id"
    t.decimal "quantity"
    t.string "movement_type"
    t.string "reference_type"
    t.uuid "reference_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_stock_movements_on_product_id"
    t.index ["warehouse_id"], name: "index_stock_movements_on_warehouse_id"
  end

  create_table "suppliers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "contact_person"
    t.string "phone"
    t.text "address"
    t.string "supplier_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country"
  end

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "related_entity_type", null: false
    t.uuid "related_entity_id", null: false
    t.datetime "transaction_date"
    t.string "transaction_type"
    t.decimal "amount"
    t.text "description"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transaction_reference"
    t.string "beneficiary"
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["related_entity_type", "related_entity_id"], name: "index_transactions_on_related_entity"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "phone"
    t.string "designation"
    t.string "role"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "accounts", column: "parent_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bank_reconciliations", "accounts"
  add_foreign_key "journal_entries", "journals"
  add_foreign_key "jute_purchases", "suppliers"
  add_foreign_key "jute_stocks", "products"
  add_foreign_key "jute_stocks", "stock_houses"
  add_foreign_key "ledger_lines", "accounts"
  add_foreign_key "ledger_lines", "chart_of_accounts"
  add_foreign_key "ledger_lines", "journal_entries"
  add_foreign_key "loans", "accounts"
  add_foreign_key "processing_batches", "products", column: "input_product_id"
  add_foreign_key "processing_batches", "products", column: "output_product_id"
  add_foreign_key "purchase_items", "jute_purchases", column: "purchase_id"
  add_foreign_key "purchase_items", "products"
  add_foreign_key "reconciliation_items", "bank_reconciliations"
  add_foreign_key "reconciliation_items", "journal_entries"
  add_foreign_key "salaries", "users"
  add_foreign_key "sales_contracts", "buyers"
  add_foreign_key "sales_items", "products"
  add_foreign_key "sales_items", "sales_contracts", column: "sales_order_id"
  add_foreign_key "shipment_documents", "shipments"
  add_foreign_key "shipments", "sales_contracts", column: "sales_order_id"
  add_foreign_key "stock_movements", "products"
  add_foreign_key "stock_movements", "stock_houses", column: "warehouse_id"
  add_foreign_key "transactions", "accounts"
end
