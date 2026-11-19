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

ActiveRecord::Schema[8.1].define(version: 2026_11_19_000304) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "citations", force: :cascade do |t|
    t.bigint "source_id", null: false
    t.string "citable_type", null: false
    t.bigint "citable_id", null: false
    t.string "page"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["citable_type", "citable_id"], name: "index_citations_on_citable"
    t.index ["source_id"], name: "index_citations_on_source_id"
  end

  create_table "event_participants", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "person_id", null: false
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "person_id"], name: "index_event_participants_on_event_id_and_person_id", unique: true
    t.index ["event_id"], name: "index_event_participants_on_event_id"
    t.index ["person_id"], name: "index_event_participants_on_person_id"
  end

  create_table "event_revelations", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "revelation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "revelation_id"], name: "index_event_revelations_on_event_id_and_revelation_id", unique: true
    t.index ["event_id"], name: "index_event_revelations_on_event_id"
    t.index ["revelation_id"], name: "index_event_revelations_on_revelation_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.string "date_precision", default: "exact", null: false
    t.string "category", null: false
    t.string "period", null: false
    t.text "summary"
    t.text "context"
    t.bigint "place_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_events_on_category"
    t.index ["period"], name: "index_events_on_period"
    t.index ["place_id"], name: "index_events_on_place_id"
    t.index ["slug"], name: "index_events_on_slug", unique: true
    t.index ["start_date"], name: "index_events_on_start_date"
  end

  create_table "images", force: :cascade do |t|
    t.string "imageable_type", null: false
    t.bigint "imageable_id", null: false
    t.string "file_name", null: false
    t.string "caption"
    t.string "credit"
    t.string "license"
    t.integer "year"
    t.boolean "is_modern", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_url"
    t.index ["imageable_type", "imageable_id"], name: "index_images_on_imageable"
  end

  create_table "membership_estimates", force: :cascade do |t|
    t.integer "year", null: false
    t.integer "members", null: false
    t.boolean "is_approximate", default: true, null: false
    t.text "note"
    t.bigint "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_id"], name: "index_membership_estimates_on_source_id"
    t.index ["year"], name: "index_membership_estimates_on_year", unique: true
  end

  create_table "people", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.date "birth_date"
    t.date "death_date"
    t.string "roles"
    t.text "biography"
    t.jsonb "clues", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_people_on_slug", unique: true
  end

  create_table "places", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "modern_name"
    t.string "state"
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.string "kinds", default: [], null: false, array: true
    t.text "summary"
    t.text "significance"
    t.integer "start_year"
    t.integer "end_year"
    t.integer "trail_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_places_on_slug", unique: true
  end

  create_table "revelation_people", force: :cascade do |t|
    t.bigint "revelation_id", null: false
    t.bigint "person_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id"], name: "index_revelation_people_on_person_id"
    t.index ["revelation_id", "person_id"], name: "index_revelation_people_on_revelation_id_and_person_id", unique: true
    t.index ["revelation_id"], name: "index_revelation_people_on_revelation_id"
  end

  create_table "revelations", force: :cascade do |t|
    t.integer "section_number"
    t.string "title", null: false
    t.string "slug", null: false
    t.date "received_on"
    t.string "date_precision", default: "exact", null: false
    t.text "summary"
    t.string "subjects"
    t.text "context"
    t.bigint "place_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["place_id"], name: "index_revelations_on_place_id"
    t.index ["received_on"], name: "index_revelations_on_received_on"
    t.index ["section_number"], name: "index_revelations_on_section_number", unique: true
    t.index ["slug"], name: "index_revelations_on_slug", unique: true
  end

  create_table "sources", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.string "author"
    t.date "published_on"
    t.string "url"
    t.text "citation"
    t.string "kind", default: "secondary", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_sources_on_slug", unique: true
  end

  create_table "trivia_questions", force: :cascade do |t|
    t.string "mode", default: "general", null: false
    t.string "difficulty", default: "medium", null: false
    t.text "prompt", null: false
    t.jsonb "choices", default: [], null: false
    t.string "answer", null: false
    t.text "explanation"
    t.string "subject_type"
    t.bigint "subject_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mode", "difficulty"], name: "index_trivia_questions_on_mode_and_difficulty"
    t.index ["subject_type", "subject_id"], name: "index_trivia_questions_on_subject"
  end

  create_table "verses", force: :cascade do |t|
    t.bigint "revelation_id", null: false
    t.integer "number", null: false
    t.text "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["revelation_id", "number"], name: "index_verses_on_revelation_id_and_number", unique: true
    t.index ["revelation_id"], name: "index_verses_on_revelation_id"
  end

  add_foreign_key "citations", "sources"
  add_foreign_key "event_participants", "events"
  add_foreign_key "event_participants", "people"
  add_foreign_key "event_revelations", "events"
  add_foreign_key "event_revelations", "revelations"
  add_foreign_key "events", "places"
  add_foreign_key "membership_estimates", "sources"
  add_foreign_key "revelation_people", "people"
  add_foreign_key "revelation_people", "revelations"
  add_foreign_key "revelations", "places"
  add_foreign_key "verses", "revelations"
end
