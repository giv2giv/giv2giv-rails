class RenameTypeDonationToCharityGroupVisibility < ActiveRecord::Migration
  def change
    rename_column :charity_groups, :type_donation, :charity_group_visibility
  end
end
