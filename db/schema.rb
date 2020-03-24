# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_03_22_062650) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clusters", force: :cascade do |t|
    t.string "name", null: false
    t.string "subdomain", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["subdomain"], name: "index_clusters_on_subdomain", unique: true
  end

  create_table "servers", force: :cascade do |t|
    t.string "ip_string", null: false
    t.string "friendly_name"
    t.bigint "cluster_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["ip_string"], name: "index_servers_on_ip_string", unique: true
  end

end
