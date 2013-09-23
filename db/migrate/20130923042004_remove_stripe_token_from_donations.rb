class RemoveStripeTokenFromDonations < ActiveRecord::Migration
  def change
    remove_column :donations, :stripe_token if ActiveRecord::Base.connection.column_exists?(:donations, :stripe_token)
    remove_column :donations, :cust_id if ActiveRecord::Base.connection.column_exists?(:donations, :cust_id)
  end
end
