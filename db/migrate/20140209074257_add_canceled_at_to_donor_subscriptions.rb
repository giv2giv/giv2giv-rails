class AddCanceledAtToDonorSubscriptions < ActiveRecord::Migration
  def change
    add_column :donor_subscriptions, :canceled_at, :datetime
  end
end
