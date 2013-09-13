class CreateSharesTable < ActiveRecord::Migration
  def change
    create_table :shares do |t|
      t.timestamps
      t.integer :donor_id, null: false
      t.integer :charity_group_id, null: false
      t.string :count, null: false
      t.float :price_at_issue
    end
  end
end
