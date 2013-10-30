class CreateTableForShares < ActiveRecord::Migration
  def change
    create_table :shares do |t|
      t.float :stripe_balance
      t.float :etrade_balance
      t.float :share_total_beginning
      t.float :shares_added_by_donation
      t.float :shares_subtracted_by_grants
      t.float :share_total_end
      t.float :share_price
      t.timestamps
    end

    create_table :grants do |t|
      t.integer :donor_id
      t.integer :endowment_id
      t.integer :dwolla_transaction_id
      t.date :date
      t.float :shares_subtracted
      t.timestamps
    end

    add_column :donations, :shares_purchased, :string
    add_column :donations, :shares_added, :float
    add_column :donations, :donor_id, :integer

  end
end
