class AddCharityIdToDonorSubscriptions < ActiveRecord::Migration
  def change
    add_column :donor_subscriptions, :charity_id, :integer
	end
end
