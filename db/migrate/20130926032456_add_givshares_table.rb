class AddGivsharesTable < ActiveRecord::Migration
    def change
    create_table :givshares do |t|
      t.integer :endowment_id, null: false
      t.float :stripe_balance
      t.float :etrade_balance
      t.float :shares_outstanding_beginning
      t.float :shares_bought_through_donations
      t.float :shares_outstanding_end
      t.float :donation_price
      t.float :round_down_price
      t.timestamps
    end

    add_index :givshares, :updated_at
  end
end
