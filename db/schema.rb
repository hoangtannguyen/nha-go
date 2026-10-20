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

ActiveRecord::Schema[8.1].define(version: 2026_10_20_120000) do
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

  create_table "admin_users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.boolean "active", default: true, null: false
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "description"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.string "phone", null: false
    t.string "name", null: false
    t.text "address"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phone"], name: "index_customers_on_phone", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.string "name", null: false
    t.integer "price", default: 0, null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "code", null: false
    t.string "customer_name", null: false
    t.string "phone", null: false
    t.text "address", null: false
    t.text "note"
    t.integer "total", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "customer_id"
    t.string "street"
    t.integer "ward_code"
    t.string "ward_name"
    t.integer "province_code"
    t.string "province_name"
    t.string "email"
    t.string "carrier"
    t.string "tracking_code"
    t.integer "shipping_fee"
    t.datetime "shipment_created_at"
    t.string "estimated_deliver_time"
    t.integer "carrier_status_id"
    t.string "carrier_status_reason"
    t.datetime "carrier_status_updated_at"
    t.text "shipment_error"
    t.datetime "shipping_notified_at"
    t.index ["code"], name: "index_orders_on_code", unique: true
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["province_code"], name: "index_orders_on_province_code"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["tracking_code"], name: "index_orders_on_tracking_code", unique: true
  end

  create_table "page_views", force: :cascade do |t|
    t.string "visitor_id", null: false
    t.string "path", null: false
    t.integer "product_id"
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_page_views_on_created_at"
    t.index ["product_id"], name: "index_page_views_on_product_id"
    t.index ["visitor_id"], name: "index_page_views_on_visitor_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "tag"
    t.string "image"
    t.string "size_label"
    t.integer "price", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "colors"
    t.json "sizes"
    t.integer "category_id", null: false
    t.boolean "sold_out", default: false, null: false
    t.boolean "hidden", default: false, null: false
    t.integer "sale_price"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["position"], name: "index_products_on_position"
  end

  create_table "site_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "about_title"
    t.string "about_title_highlight"
    t.text "about_body"
    t.string "about_quote"
    t.string "hero_lead"
    t.string "hero_stat_1_value"
    t.string "hero_stat_1_label"
    t.string "hero_stat_2_value"
    t.string "hero_stat_2_label"
    t.string "hero_stat_3_value"
    t.string "hero_stat_3_label"
  end

  create_table "subscribers", force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.string "phone"
    t.string "unsubscribe_token", null: false
    t.boolean "active", default: true, null: false
    t.datetime "subscribed_at", null: false
    t.datetime "unsubscribed_at"
    t.datetime "last_emailed_at"
    t.integer "emails_sent_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_subscribers_on_active"
    t.index ["email"], name: "index_subscribers_on_email", unique: true
    t.index ["unsubscribe_token"], name: "index_subscribers_on_unsubscribe_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "customers"
  add_foreign_key "page_views", "products", on_delete: :nullify
  add_foreign_key "products", "categories"
end
