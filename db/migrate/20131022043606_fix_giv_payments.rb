class FixGivPayments < ActiveRecord::Migration
  def change
    remove_column :giv_payments, :dwolla_transaction_id if ActiveRecord::Base.connection.column_exists?(:giv_payments, :dwolla_transaction_id)
    add_column :giv_payments, :from_etrade_to_dwolla_transaction_id, :string
    add_column :giv_payments, :from_dwolla_to_giv2giv_transaction_id, :string
    add_column :giv_payments, :status, :string
  end
end
