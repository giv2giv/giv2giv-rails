class RemoveSentGrantAndGrantTable < ActiveRecord::Migration
  def change
    add_column :donor_grants, :date, :date
    add_column :donor_grants, :transaction_id, :integer
    drop_table :sent_grants
    drop_table :grants
  end
end
