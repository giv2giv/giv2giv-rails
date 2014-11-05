class ChangeCharityOthersToBigInt < ActiveRecord::Migration
  def up
    change_column :charities, :income_amount, :integer, :limit => 8
    change_column :charities, :revenue_amount, :integer, :limit => 8
  end

  def down
    change_column :charities, :income_amount, :integer
    change_column :charities, :revenue_amount, :integer
  end
end
