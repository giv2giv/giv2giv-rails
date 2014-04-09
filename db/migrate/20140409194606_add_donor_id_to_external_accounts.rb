class AddDonorIdToExternalAccounts < ActiveRecord::Migration
  def change
    add_column :external_accounts, :donor_id, :integer
    add_index :external_accounts, :donor_id
  end
end
