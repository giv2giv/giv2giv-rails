class ChangeGrantAmountPrecision < ActiveRecord::Migration
  def up
    change_column :grants, :grant_amount, :decimal, :precision => 30, :scale => 2, null: false
  end

  def down
    change_column :grants, :grant_amount, :decimal, :precision => 30, :scale => 20, null: false
  end
end
