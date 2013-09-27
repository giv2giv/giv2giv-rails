class AddColumnGivshareIdToSharesTables < ActiveRecord::Migration
  def change
    add_column :shares, :givshare_id, :integer
  end
end
