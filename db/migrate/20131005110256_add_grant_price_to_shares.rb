class AddGrantPriceToShares < ActiveRecord::Migration
  def change
    add_column :shares, :grant_price, :float
    rename_column :shares, :share_price, :donation_price
    rename_column :grants, :givfee, :giv2giv_total_grant_fee
    remove_column :donations, :shares_purchased if ActiveRecord::Base.connection.column_exists?(:donations, :shares_purchased)
    remove_column :grants, :dwolla_transaction_id if ActiveRecord::Base.connection.column_exists?(:grants, :dwolla_transaction_id)
  end
end