class AddDonorIdToCharityGroups < ActiveRecord::Migration
  def change
    add_column :charity_groups, :donor_id, :integer
  end
end
