class RemoveEndowmentIdDonorIdDateFromCharityGrants < ActiveRecord::Migration
  def up
    change_table :charity_grants do |t|
      t.remove :endowment_id, :donor_id, :date
    end
  end

  def down
    change_table :charity_grants do |t|
      t.add_column :endowment_id, :donor_id, :integer
      t.add_column :date, :date
    end
  end
end
