class MoveStripeCustIdToPaymentAccounts < ActiveRecord::Migration
  def change
    remove_column :donors, :stripe_cust_id if ActiveRecord::Base.connection.column_exists?(:donors, :stripe_cust_id)
    add_column :payment_accounts, :stripe_cust_id, :string
  end
end
