class ExpandDonations < ActiveRecord::Migration
  def change
    rename_column :donations, :amount, :gross_amount
    add_column :donations, :transaction_fees, :float
    add_column :donations, :net_amount, :float
  end
end
