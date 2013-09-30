class AddDonationIdToGivshares < ActiveRecord::Migration
  def change
    add_column :givshares, :donation_id, :integer
  end
end
