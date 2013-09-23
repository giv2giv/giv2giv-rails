class RemoveStripeTokenFromDonations < ActiveRecord::Migration
  def change
    remove_column :donations, :stripe_token if ActiveRecord::Base.connection.column_exists?(:donations, :stripe_token)
  end
end
