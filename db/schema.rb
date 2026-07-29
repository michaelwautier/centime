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

ActiveRecord::Schema[8.1].define(version: 2026_07_29_114116) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bank_accounts", force: :cascade do |t|
    t.bigint "balance_cents"
    t.datetime "balance_refreshed_at"
    t.bigint "bank_connection_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "EUR", null: false
    t.string "gocardless_account_id", null: false
    t.string "iban_last4"
    t.string "name"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_connection_id"], name: "index_bank_accounts_on_bank_connection_id"
    t.index ["gocardless_account_id"], name: "index_bank_accounts_on_gocardless_account_id", unique: true
  end

  create_table "bank_connections", force: :cascade do |t|
    t.datetime "consent_expires_at"
    t.datetime "created_at", null: false
    t.string "institution_id", null: false
    t.string "institution_logo_url"
    t.string "institution_name", null: false
    t.date "last_manual_sync_on"
    t.text "last_sync_error"
    t.datetime "last_synced_at"
    t.string "reference", null: false
    t.string "requisition_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["reference"], name: "index_bank_connections_on_reference", unique: true
    t.index ["requisition_id"], name: "index_bank_connections_on_requisition_id", unique: true
    t.index ["user_id"], name: "index_bank_connections_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'linked'::character varying, 'expiring'::character varying, 'expired'::character varying, 'revoked'::character varying, 'paused'::character varying, 'error'::character varying]::text[])", name: "bank_connections_status_check"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "archived_at"
    t.string "color", default: "#6b7280", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id", "name", "kind"], name: "index_categories_on_user_id_and_name_and_kind", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
    t.check_constraint "kind::text = ANY (ARRAY['income'::character varying, 'expense'::character varying]::text[])", name: "categories_kind_check"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "amount_cents", null: false
    t.bigint "bank_account_id"
    t.date "booked_on", null: false
    t.string "categorization_source", default: "none", null: false
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, null: false
    t.string "description"
    t.string "external_id"
    t.string "merchant_name"
    t.boolean "pending", default: false, null: false
    t.string "source", default: "manual", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["bank_account_id", "external_id"], name: "index_transactions_on_bank_account_and_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["bank_account_id"], name: "index_transactions_on_bank_account_id"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["user_id", "booked_on"], name: "index_transactions_on_user_id_and_booked_on"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "EUR", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "bank_accounts", "bank_connections"
  add_foreign_key "bank_connections", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "transactions", "bank_accounts"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "users"
end
