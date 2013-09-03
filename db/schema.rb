# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130902213431) do

  create_table "charities", :force => true do |t|
    t.string   "name",                :null => false
    t.integer  "ein",                 :null => false
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "ntee_code"
    t.string   "classification_code"
    t.string   "subsection_code"
    t.string   "activity_code"
    t.string   "description"
    t.string   "website"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "charities", ["ein"], :name => "index_charities_on_ein"

  create_table "charities_charity_groups", :id => false, :force => true do |t|
    t.integer "charity_group_id", :null => false
    t.integer "charity_id",       :null => false
  end

  add_index "charities_charity_groups", ["charity_group_id", "charity_id"], :name => "charity_groups_charities_compound"
  add_index "charities_charity_groups", ["charity_group_id"], :name => "index_charities_charity_groups_on_charity_group_id"
  add_index "charities_charity_groups", ["charity_id"], :name => "index_charities_charity_groups_on_charity_id"

  create_table "charities_tags", :id => false, :force => true do |t|
    t.integer "charity_id", :null => false
    t.integer "tag_id",     :null => false
  end

  add_index "charities_tags", ["charity_id", "tag_id"], :name => "index_charities_tags_on_charity_id_and_tag_id", :unique => true

  create_table "charity_groups", :force => true do |t|
    t.string   "name",                    :null => false
    t.string   "description"
    t.float    "minimum_donation_amount"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  create_table "donations", :force => true do |t|
    t.float    "amount",                :null => false
    t.integer  "charity_group_id",      :null => false
    t.integer  "payment_account_id",    :null => false
    t.string   "transaction_id",        :null => false
    t.string   "transaction_processor", :null => false
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  add_index "donations", ["charity_group_id"], :name => "index_donations_on_charity_group_id"
  add_index "donations", ["payment_account_id"], :name => "index_donations_on_payment_account_id"

  create_table "donors", :force => true do |t|
    t.string   "name",          :null => false
    t.string   "email",         :null => false
    t.string   "password_hash", :null => false
    t.string   "facebook_id"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "country"
    t.string   "phone_number"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "etrades", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.datetime "date"
    t.float    "balance",    :null => false
    t.float    "fees"
  end

  create_table "payment_accounts", :force => true do |t|
    t.string   "processor",                          :null => false
    t.string   "token"
    t.string   "pin"
    t.integer  "donor_id",                           :null => false
    t.boolean  "requires_reauth", :default => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "payment_accounts", ["donor_id"], :name => "index_payment_accounts_on_donor_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "tags", :force => true do |t|
    t.text     "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "tags", ["id"], :name => "index_tags_on_id"

end
