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

ActiveRecord::Schema[7.1].define(version: 2026_04_29_194117) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "collection_items", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "product_id", null: false
    t.datetime "added_at", default: -> { "now()" }, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_collection_items_on_product_id"
    t.index ["user_id", "product_id"], name: "index_collection_items_on_user_id_and_product_id", unique: true
    t.index ["user_id"], name: "index_collection_items_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "canonical_name", null: false
    t.string "publisher"
    t.string "edition"
    t.string "language", default: "pt-BR"
    t.string "category", null: false
    t.string "slug", null: false
    t.string "aliases", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "BRL", null: false
    t.integer "estimated_price_cents", default: 0, null: false
    t.string "estimated_price_currency", default: "BRL", null: false
    t.datetime "current_price_updated_at"
    t.index ["canonical_name"], name: "index_products_on_canonical_name"
    t.index ["category"], name: "index_products_on_category"
    t.index ["slug"], name: "index_products_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "phone"
    t.string "consent_status", default: "pending", null: false
    t.datetime "consent_at"
    t.string "consent_ip"
    t.string "privacy_policy_version", default: "1.0"
    t.datetime "anonymized_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consent_status"], name: "index_users_on_consent_status"
    t.index ["phone"], name: "index_users_on_phone", unique: true, where: "(phone IS NOT NULL)"
  end

  add_foreign_key "collection_items", "products"
  add_foreign_key "collection_items", "users"
end
