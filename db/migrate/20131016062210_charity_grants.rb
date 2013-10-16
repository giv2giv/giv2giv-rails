class CharityGrants < ActiveRecord::Migration
  def change
    create_table :charity_grants do |t|
      t.integer :charity_id
      t.integer :charity_group_id
      t.integer :donor_id
      t.decimal   :shares_subtracted
      t.integer :transaction_id
      t.date    :date
      t.decimal   :transaction_fee
      t.decimal   :giv2giv_fee
      t.decimal   :gross_amount
      t.decimal   :grant_amount
      t.string  :status
      t.timestamps
    end
  end
end
