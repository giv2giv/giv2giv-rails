class ChangeColumnNameCharities < ActiveRecord::Migration
  def change
    rename_column :charities, :status, :active
  end
end
