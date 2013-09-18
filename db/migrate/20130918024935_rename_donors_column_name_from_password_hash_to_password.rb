class RenameDonorsColumnNameFromPasswordHashToPassword < ActiveRecord::Migration
  def up
    rename_column :donors, :password_hash, :password
  end
end