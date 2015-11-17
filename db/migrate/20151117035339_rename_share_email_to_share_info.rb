class RenameShareEmailToShareInfo < ActiveRecord::Migration
  def change
    rename_column :donors, :share_email, :share_info
  end
end
