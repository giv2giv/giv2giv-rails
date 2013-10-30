class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :donor_subscriptions do |t|
      t.integer :donor_id
      t.integer :payment_account_id
      t.integer :endowment_id
      t.string  :stripe_subscription_id
      t.string  :type_donation
      t.timestamps
    end
  end
end
