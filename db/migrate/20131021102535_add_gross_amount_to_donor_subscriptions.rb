class AddGrossAmountToDonorSubscriptions < ActiveRecord::Migration
  def change
    add_column :donor_subscriptions, :gross_amount, :float
  end
end
