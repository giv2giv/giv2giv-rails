class ChangeGrossAmountToDecimal < ActiveRecord::Migration
  def up
    change_column :donor_subscriptions, :gross_amount, :decimal, :precision => 30, :scale => 2, null: false
  end

  def down
    change_column :donor_subscriptions, :gross_amount, :float, null: false
  end
end
