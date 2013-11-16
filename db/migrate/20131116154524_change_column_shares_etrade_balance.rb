class ChangeColumnSharesEtradeBalance < ActiveRecord::Migration
  def change
    change_column :shares, :etrade_balance, :decimal, :precision => 30, :scale => 20
  end
end
