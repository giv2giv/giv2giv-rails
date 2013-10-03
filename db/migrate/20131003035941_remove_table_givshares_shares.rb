class RemoveTableGivsharesShares < ActiveRecord::Migration
  def change
    drop_table :givshares
    drop_table :shares
  end
end
