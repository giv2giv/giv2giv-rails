class RenameSessionsColumnDataToToken < ActiveRecord::Migration
  def change
    change_column :sessions, :data, :string, :null => false
    rename_column :sessions, :data, :token
  end
end
