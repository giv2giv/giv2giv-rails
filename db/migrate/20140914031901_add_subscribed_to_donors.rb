class AddSubscribedToDonors < ActiveRecord::Migration
	def self.up
    add_column :donors, :subscribed, :boolean
  end

  def self.down
    remove_column :donor, :subscribed, :boolean
  end
end
