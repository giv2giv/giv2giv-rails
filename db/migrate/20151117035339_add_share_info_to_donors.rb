class AddShareInfoToDonors < ActiveRecord::Migration
  def change
     add_column :donors, :share_info, :boolean, :default=>true 
  end
end
