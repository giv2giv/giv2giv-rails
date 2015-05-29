class RenameStripeSubscriptionIdToUniqueSubscriptionId < ActiveRecord::Migration
  def change
    rename_column :donor_subscriptions, :stripe_subscription_id, :unique_subscription_id
  end
end
