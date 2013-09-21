class RemoveTokenPinFromPaymentAccounts < ActiveRecord::Migration
  def change
    remove_column :payment_accounts, :token if ActiveRecord::Base.connection.column_exists?(:payment_accounts, :token)
    remove_column :payment_accounts, :pin if ActiveRecord::Base.connection.column_exists?(:payment_accounts, :pin)
  end
end