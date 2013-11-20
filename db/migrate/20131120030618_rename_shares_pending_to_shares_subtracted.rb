class RenameSharesPendingToSharesSubtracted < ActiveRecord::Migration
  def up
    change_table :donor_grants do |t|
      t.rename :shares_pending, :shares_subtracted
    end
  end

  def down
    change_table :donor_grants do |t|
      t.rename :shares_subtracted, :shares_pending
    end
  end
end
