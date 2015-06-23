class AddPercentPassthruToSubscriptions < ActiveRecord::Migration
  def change
    add_column :donor_subscriptions, :passthru_percent, :integer
  end
end
