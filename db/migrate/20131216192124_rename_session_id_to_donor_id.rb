class RenameSessionIdToDonorId < ActiveRecord::Migration
  def up
    remove_index :sessions, :session_id
    rename_column :sessions, :session_id, :donor_id
    add_index :sessions, :donor_id
  end

  def down
    remove_index :sessions, :donor_id
    rename_column :sessions, :donor_id, :session_id
    add_index :sessions, :session_id
  end
end

