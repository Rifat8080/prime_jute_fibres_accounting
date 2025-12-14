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

ActiveRecord::Schema[8.0].define(version: 2025_12_14_141500) do
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

  create_table "buyers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "company_name"
    t.string "contact_person"
    t.string "email"
    t.string "phone"
    t.text "address"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "jute_purchases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "supplier_id", null: false
    t.date "purchase_date"
    t.string "jute_variety"
    t.decimal "quantity_kg"
    t.decimal "rate_per_kg"
    t.decimal "total_amount"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id"], name: "index_jute_purchases_on_supplier_id"
  end

  create_table "jute_stocks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "stock_house_id", null: false
    t.string "jute_quality"
    t.decimal "quantity_bales"
    t.datetime "last_updated"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_house_id"], name: "index_jute_stocks_on_stock_house_id"
  end

  create_table "processing_costs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "cost_type"
    t.decimal "cost_per_unit"
    t.string "unit_type"
    t.date "effective_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "procurement_costs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "costable_type", null: false
    t.uuid "costable_id", null: false
    t.string "cost_type"
    t.decimal "amount"
    t.date "cost_date"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["costable_type", "costable_id"], name: "index_procurement_costs_on_costable"
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
    t.uuid "buyer_id", null: false
    t.string "contract_type"
    t.string "contract_number"
    t.date "contract_date"
    t.jsonb "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_sales_contracts_on_buyer_id"
    t.index ["contract_number"], name: "index_sales_contracts_on_contract_number", unique: true
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
    t.uuid "sales_contract_id", null: false
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
    t.index ["sales_contract_id"], name: "index_shipments_on_sales_contract_id"
    t.index ["stock_house_id"], name: "index_shipments_on_stock_house_id"
  end

  create_table "stock_houses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stock_movements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "jute_stock_id", null: false
    t.string "source_type", null: false
    t.uuid "source_id", null: false
    t.string "movement_type"
    t.decimal "quantity_bales"
    t.datetime "movement_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jute_stock_id"], name: "index_stock_movements_on_jute_stock_id"
    t.index ["source_type", "source_id"], name: "index_stock_movements_on_source"
  end

  create_table "suppliers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "contact_person"
    t.string "phone"
    t.text "address"
    t.string "supplier_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "jute_purchases", "suppliers"
  add_foreign_key "jute_stocks", "stock_houses"
  add_foreign_key "salaries", "users"
  add_foreign_key "sales_contracts", "buyers"
  add_foreign_key "shipment_documents", "shipments"
  add_foreign_key "shipments", "sales_contracts"
  add_foreign_key "shipments", "stock_houses"
  add_foreign_key "stock_movements", "jute_stocks"
  add_foreign_key "transactions", "accounts"
end
