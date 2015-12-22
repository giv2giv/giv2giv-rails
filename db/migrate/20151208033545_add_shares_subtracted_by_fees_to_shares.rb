class AddSharesSubtractedByFeesToShares < ActiveRecord::Migration
  def change
  	add_column :shares, :shares_subtracted_by_fees, :decimal, :precision => 30, :scale => 20
  end
end
