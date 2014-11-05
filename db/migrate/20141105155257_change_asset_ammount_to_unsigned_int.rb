class ChangeAssetAmmountToUnsignedInt < ActiveRecord::Migration
  def up
    change_column :charities, :asset_amount, :integer, :limit => 8
  end

  def down
    change_column :charities, :asset_amount, :integer
  end
end
