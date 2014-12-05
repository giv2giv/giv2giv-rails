class AddFieldsToShare < ActiveRecord::Migration
  def change
    add_column :shares, :dwolla_balance, :decimal, :precision => 30, :scale => 2, null: false
    add_column :shares, :transit_balance, :decimal, :precision => 30, :scale => 2, null: false
  end
end
