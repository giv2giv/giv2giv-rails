class CreateTableForShares < ActiveRecord::Migration
  def change
    create_table :shares do |t|
      t.decimal :stripe_balance
      t.decimal :etrade_balance
      t.decimal :share_total_beginning
      t.decimal :shares_added_by_donation
      t.decimal :shares_subtracted_by_grants
      t.decimal :share_total_end
      t.decimal :share_price
      t.timestamps
    end

    create_table :grants do |t|
      t.integer :donor_id
      t.integer :charity_group_id
      t.integer :dwolla_transaction_id
      t.date :date
      t.decimal :shares_subtracted
      t.timestamps
    end

    add_column :donations, :shares_purchased, :string
    add_column :donations, :shares_added, :decimal
    add_column :donations, :donor_id, :integer

  end
end
