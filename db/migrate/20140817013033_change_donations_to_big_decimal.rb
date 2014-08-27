class ChangeDonationsToBigDecimal < ActiveRecord::Migration
  def up
    change_column :donations, :gross_amount, :decimal, :precision => 30, :scale => 2, null: false
    rename_column :donations, :transaction_fees, :transaction_fee
    change_column :donations, :transaction_fee, :decimal, :precision => 10, :scale => 2, null: false
    change_column :donations, :net_amount, :decimal, :precision => 30, :scale => 2, null: false
  end

  def down
  	raise ActiveRecord::IrreversibleMigration
  end
end
