class AddShareTotalAndGrantToGivshares < ActiveRecord::Migration
  def change
    add_column :givshares, :share_total, :decimal
    add_column :givshares, :share_granted, :decimal
    add_column :givshares, :donor_grant, :decimal
    add_column :givshares, :is_grant, :integer
    add_column :givshares, :etrade_adjustment, :decimal
    add_column :givshares, :charity_group_balance, :decimal
    add_column :givshares, :count, :integer
  end
end
