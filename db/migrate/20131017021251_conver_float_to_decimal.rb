class ConverFloatToDecimal < ActiveRecord::Migration
  def change
    add_column :donor_grants, :shares_pending, :decimal, :precision => 20
    change_column :donations, :shares_added, :decimal, :precision => 20
    change_column :charity_grants, :shares_subtracted, :decimal, :precision => 20
    change_column :charity_grants, :giv2giv_fee, :decimal, :precision => 20
    change_column :charity_grants, :gross_amount, :decimal, :precision => 20
    change_column :charity_grants, :grant_amount, :decimal, :precision => 20
    change_column :grants, :shares_subtracted, :decimal, :precision => 20
    change_column :grants, :giv2giv_total_grant_fee, :decimal, :precision => 20
    change_column :shares, :share_total_beginning, :decimal, :precision => 20
    change_column :shares, :shares_added_by_donation, :decimal, :precision => 20
    change_column :shares, :shares_subtracted_by_grants, :decimal, :precision => 20
    change_column :shares, :share_total_end, :decimal, :precision => 20
    change_column :shares, :grant_price, :decimal, :precision => 20
    change_column :shares, :donation_price, :decimal, :precision => 20
  end
end
