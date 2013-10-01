class AddShareTotalAndGrantToGivshares < ActiveRecord::Migration
  def change
    add_column :givshares, :share_total, :float
    add_column :givshares, :share_granted, :float
    add_column :givshares, :donor_grant, :float
    add_column :givshares, :is_grant, :integer
    add_column :givshares, :etrade_adjustment, :float
    add_column :givshares, :charity_group_balance, :float
    add_column :givshares, :count, :integer
  end
end
