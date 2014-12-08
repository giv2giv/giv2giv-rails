class ChangeTypeToGrantType < ActiveRecord::Migration
  def change
    rename_column :grants, :type, :grant_type
  end
end
