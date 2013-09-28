class AddColumnDonorIdToGivshares < ActiveRecord::Migration
  def change
    add_column :givshares, :donor_id, :integer
  end
end
