class RemoveBalanceAndFeesFromCharities < ActiveRecord::Migration

  def up
    change_table :charities do |t|
      t.remove :balance, :giv2giv_fees, :transaction_fees
    end
  end

  def down
    change_table :charities do |t|
      t.add_column :balance, :giv2giv_fees, :transaction_fees, :float
    end
  end
end
