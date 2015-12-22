class RemoveGrantGiv2givFee < ActiveRecord::Migration
  def up
  	remove_column :grants, :giv2giv_fee
  end
  def down
    add_column :grants, :giv2giv_fee, :decimal, :precision => 30, :scale => 2
  end
end
