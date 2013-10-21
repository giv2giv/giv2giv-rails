class FixColumnSubscriptions < ActiveRecord::Migration
  def change
    rename_column :donor_subscriptions, :type_donation, :type_subscription
  end
end