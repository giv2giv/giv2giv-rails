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

ActiveRecord::Schema.define(:version => 20140409194606) do

  create_table "charities", :force => true do |t|
    t.string   "name",                :null => false
    t.string   "ein",                 :null => false
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
    t.string   "email"
    t.string   "active"
  end

  add_index "charities", ["ein"], :name => "index_charities_on_ein"
  add_index "charities", ["name"], :name => "index_charities_on_name"

  create_table "charities_endowments", :id => false, :force => true do |t|
    t.integer "endowment_id", :null => false
    t.integer "charity_id",   :null => false
  end

  add_index "charities_endowments", ["charity_id"], :name => "index_charities_endowments_on_charity_id"
  add_index "charities_endowments", ["endowment_id", "charity_id"], :name => "endowments_charities_compound"
  add_index "charities_endowments", ["endowment_id"], :name => "index_charities_endowments_on_endowment_id"

  create_table "charities_tags", :id => false, :force => true do |t|
    t.integer "charity_id", :null => false
    t.integer "tag_id",     :null => false
  end

  add_index "charities_tags", ["charity_id", "tag_id"], :name => "index_charities_tags_on_charity_id_and_tag_id", :unique => true

  create_table "charity_grants", :force => true do |t|
    t.integer  "charity_id"
    t.decimal  "shares_subtracted", :precision => 30, :scale => 20
    t.integer  "transaction_id"
    t.float    "transaction_fee"
    t.float    "giv2giv_fee"
    t.float    "gross_amount"
    t.float    "grant_amount"
    t.string   "status"
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
  end

  create_table "donations", :force => true do |t|
    t.float    "gross_amount",                                       :null => false
    t.integer  "endowment_id",                                       :null => false
    t.integer  "payment_account_id",                                 :null => false
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.decimal  "shares_added",       :precision => 30, :scale => 20
    t.integer  "donor_id"
    t.float    "transaction_fees"
    t.float    "net_amount"
  end

  add_index "donations", ["endowment_id"], :name => "index_donations_on_endowment_id"
  add_index "donations", ["payment_account_id"], :name => "index_donations_on_payment_account_id"

  create_table "donor_grants", :force => true do |t|
    t.integer  "charity_id"
    t.integer  "endowment_id"
    t.integer  "donor_id"
    t.string   "status"
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
    t.decimal  "shares_subtracted", :precision => 30, :scale => 20
    t.date     "date"
    t.integer  "transaction_id"
    t.decimal  "gross_amount",      :precision => 30, :scale => 20
    t.decimal  "giv2giv_fee",       :precision => 30, :scale => 20
    t.decimal  "transaction_fee",   :precision => 30, :scale => 20
    t.decimal  "net_amount",        :precision => 30, :scale => 20
  end

  create_table "donor_subscriptions", :force => true do |t|
    t.integer  "donor_id"
    t.integer  "payment_account_id"
    t.integer  "endowment_id"
    t.string   "stripe_subscription_id"
    t.string   "type_subscription"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
    t.float    "gross_amount"
    t.datetime "canceled_at"
    t.date     "next_charge_date"
  end

  create_table "donors", :force => true do |t|
    t.string   "name",                  :null => false
    t.string   "email",                 :null => false
    t.string   "password",              :null => false
    t.string   "facebook_id"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "country"
    t.string   "phone_number"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.string   "type_donor"
    t.string   "password_reset_token"
    t.datetime "expire_password_reset"
    t.string   "auth_token"
    t.datetime "accepted_terms"
    t.datetime "accepted_terms_on",     :null => false
  end

  create_table "endowments", :force => true do |t|
    t.string   "name",                    :null => false
    t.string   "description"
    t.float    "minimum_donation_amount"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
    t.integer  "donor_id"
    t.string   "visibility"
    t.string   "slug"
  end

  add_index "endowments", ["slug"], :name => "index_endowments_on_slug", :unique => true

  create_table "etrade_tokens", :force => true do |t|
    t.string   "token"
    t.string   "secret"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "etrades", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.datetime "date"
    t.float    "balance",    :null => false
    t.float    "fees"
  end

  create_table "external_accounts", :force => true do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.string   "oauth_token"
    t.datetime "oauth_expires_at"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.integer  "donor_id"
  end

  add_index "external_accounts", ["donor_id"], :name => "index_external_accounts_on_donor_id"

  create_table "giv_payments", :force => true do |t|
    t.float    "amount"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.string   "from_etrade_to_dwolla_transaction_id"
    t.string   "from_dwolla_to_giv2giv_transaction_id"
    t.string   "status"
  end

  create_table "payment_accounts", :force => true do |t|
    t.string   "processor",                          :null => false
    t.integer  "donor_id",                           :null => false
    t.boolean  "requires_reauth", :default => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "stripe_cust_id"
  end

  add_index "payment_accounts", ["donor_id"], :name => "index_payment_accounts_on_donor_id"

  create_table "sessions", :force => true do |t|
    t.string   "donor_id",   :null => false
    t.string   "token",      :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["donor_id"], :name => "index_sessions_on_donor_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "shares", :force => true do |t|
    t.decimal  "share_total_beginning",       :precision => 30, :scale => 20
    t.decimal  "shares_added_by_donation",    :precision => 30, :scale => 20
    t.decimal  "shares_subtracted_by_grants", :precision => 30, :scale => 20
    t.decimal  "share_total_end",             :precision => 30, :scale => 20
    t.datetime "created_at",                                                  :null => false
    t.datetime "updated_at",                                                  :null => false
    t.decimal  "stripe_balance",              :precision => 10, :scale => 2
    t.decimal  "etrade_balance",              :precision => 10, :scale => 2
    t.decimal  "donation_price",              :precision => 10, :scale => 2
    t.decimal  "grant_price",                 :precision => 10, :scale => 2
  end

  create_table "stripe_logs", :force => true do |t|
    t.string   "type"
    t.text     "event"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "tags", :force => true do |t|
    t.string   "name",       :limit => 1024
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "tags", ["id"], :name => "index_tags_on_id"
  add_index "tags", ["name"], :name => "index_tags_on_name", :length => {"name"=>255}

  create_table "wishes", :force => true do |t|
    t.integer  "donor_id"
    t.text     "page"
    t.text     "wish_text"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
