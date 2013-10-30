class CharityGrants < ActiveRecord::Migration
  def change
    create_table :charity_grants do |t|
      t.integer   :charity_id
      t.integer   :endowment_id
      t.integer   :donor_id
      t.float   :shares_subtracted
      t.integer   :transaction_id
      t.date      :date
      t.float   :transaction_fee
      t.float   :giv2giv_fee
      t.float   :gross_amount
      t.float   :grant_amount
      t.string    :status
      t.timestamps
    end
  end
end
