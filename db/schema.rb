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

ActiveRecord::Schema[8.1].define(version: 2026_10_02_232623) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "addresses", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "city"
    t.string "province"
    t.string "postal_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "data_migration_csv_uploads", force: :cascade do |t|
    t.bigint "data_migration_id", null: false
    t.string "filename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.string "request_id"
    t.index ["data_migration_id"], name: "index_data_migration_csv_uploads_on_data_migration_id"
  end

  create_table "data_migration_errors", force: :cascade do |t|
    t.bigint "data_migration_id", null: false
    t.string "severity"
    t.string "stage"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data_migration_id"], name: "index_data_migration_errors_on_data_migration_id"
  end

  create_table "data_migrations", force: :cascade do |t|
    t.string "source_type"
    t.string "status"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "rows_processed"
    t.integer "rows_inserted"
    t.integer "rows_updated"
    t.integer "rows_skipped"
    t.integer "rows_failed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "preprocessing_time_ms"
    t.integer "extract_time_ms"
    t.integer "transform_time_ms"
    t.integer "load_time_ms"
  end

  create_table "patients", force: :cascade do |t|
    t.string "patient_health_identifier_number"
    t.string "patient_health_identifier_number_province"
    t.string "first_name"
    t.string "last_name"
    t.string "middle_name"
    t.string "phone"
    t.string "email"
    t.date "dob"
    t.string "sex"
    t.bigint "address_id"
    t.bigint "data_migration_id"
    t.string "source_hash"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.boolean "is_current"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_patients_on_address_id"
    t.index ["data_migration_id"], name: "index_patients_on_data_migration_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "data_migration_csv_uploads", "data_migrations"
  add_foreign_key "data_migration_errors", "data_migrations"
  add_foreign_key "patients", "addresses"
  add_foreign_key "patients", "data_migrations"
end
