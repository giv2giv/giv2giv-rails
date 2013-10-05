class AddCharityFeeAndBalanceToCharities < ActiveRecord::Migration
  def change
    add_column :charities, :fee, :float
    add_column :charities, :balance, :float
  end
end
