class RemoveFacebookIdFromDonors < ActiveRecord::Migration
  def up
    remove_column :donors, :facebook_id
  end

  def down
    add_column :donors, :facebook_id, :string
  end
end
