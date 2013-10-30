class InitialMigration < ActiveRecord::Migration
  def change
    create_table :charities do |t|
      t.string :name, null: false
      t.integer :ein, null: false, unique: true
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.string :ntee_code
      t.string :classification_code
      t.string :subsection_code
      t.string :activity_code
      t.string :description
      t.string :website
      t.timestamps
    end

    add_index :charities, :ein


    create_table :endowments do |t|
      t.string :name, null: false
      t.string :description
      t.float :minimum_donation_amount
      t.timestamps
    end


    create_table :donations do |t|
      t.float :amount, null: false
      t.integer :endowment_id, null: false
      t.integer :payment_account_id, null: false
      t.string :transaction_id, null: false
      t.string :transaction_processor, null: false
      t.timestamps
    end

    add_index :donations, :endowment_id
    add_index :donations, :payment_account_id


    create_table :donors do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_hash, null: false
      t.string :facebook_id
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.string :phone_number
      t.timestamps
    end


    create_table :payment_accounts do |t|
      t.string :processor, null: false
      t.string :token
      t.string :pin
      t.integer :donor_id, null: false
      t.boolean :requires_reauth, default: false
      t.timestamps
    end

    add_index :payment_accounts, :donor_id


    create_table :charities_endowments, id: false do |t|
      t.integer :endowment_id, null: false
      t.integer :charity_id, null: false
    end

    add_index :charities_endowments, [:endowment_id, :charity_id], name: :endowments_charities_compound
    add_index :charities_endowments, :endowment_id
    add_index :charities_endowments, :charity_id

  end
end
