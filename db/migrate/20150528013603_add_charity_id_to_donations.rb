class AddCharityIdToDonations < ActiveRecord::Migration
  def change
    add_column :donations, :charity_id, :integer
	end
end
