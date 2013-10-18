class FixColumnCharity < ActiveRecord::Migration
  def change
    remove_column :charities, :fee if ActiveRecord::Base.connection.column_exists?(:charities, :fee)
    add_column :charities, :giv2giv_fees, :float
    add_column :charities, :transaction_fees, :float
  end
end
