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

ActiveRecord::Schema[8.0].define(version: 2023_10_12_142917) do
  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "entries", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.datetime "datetime", precision: nil
    t.text "body"
    t.datetime "published_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "category_id"
    t.string "type", null: false
  end

  create_table "images", force: :cascade do |t|
    t.string "orig_path", null: false
    t.string "thumb_path", null: false
    t.integer "entry_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id"], name: "index_images_on_entry_id"
  end
end
