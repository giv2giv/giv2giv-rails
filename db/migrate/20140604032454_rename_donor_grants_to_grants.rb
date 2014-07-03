class RenameDonorGrantsToGrants < ActiveRecord::Migration
  
  def change
    rename_table :donor_grants, :grants
  end

end
