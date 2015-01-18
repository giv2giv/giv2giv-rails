class AddFieldsToPaymentAccounts < ActiveRecord::Migration
  def change
  	add_column :payment_accounts, :user_key, :string
  	add_column :payment_accounts, :user_pass, :string
  end
end
