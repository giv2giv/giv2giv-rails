class FixColumn < ActiveRecord::Migration
  def change
    change_column :charity_grants, :giv2giv_fee, :float
    change_column :charity_grants, :gross_amount, :float
    change_column :charity_grants, :grant_amount, :float
    change_column :shares, :donation_price, :float
    change_column :shares, :grant_price, :float
    remove_column :donations, :transaction_processor if ActiveRecord::Base.connection.column_exists?(:donations, :transaction_processor)
    remove_column :donations, :transaction_id if ActiveRecord::Base.connection.column_exists?(:donations, :transaction_id)
    remove_column :donations, :transaction_type if ActiveRecord::Base.connection.column_exists?(:donations, :transaction_type)
  end
end
