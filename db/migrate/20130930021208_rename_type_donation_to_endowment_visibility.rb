class RenameTypeDonationToEndowmentVisibility < ActiveRecord::Migration
  def change
    rename_column :endowments, :type_donation, :endowment_visibility
  end
end
