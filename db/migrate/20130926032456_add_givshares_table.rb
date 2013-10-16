class AddGivsharesTable < ActiveRecord::Migration
    def change
    create_table :givshares do |t|
      t.integer :charity_group_id, null: false
      t.decimal :stripe_balance
      t.decimal :etrade_balance
      t.decimal :shares_outstanding_beginning
      t.decimal :shares_bought_through_donations
      t.decimal :shares_outstanding_end
      t.decimal :donation_price
      t.decimal :round_down_price
      t.timestamps
    end

    add_index :givshares, :updated_at
  end
end
