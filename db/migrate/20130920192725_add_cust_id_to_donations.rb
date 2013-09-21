class AddCustIdToDonations < ActiveRecord::Migration
  def change
    add_column :donations, :cust_id, :string
  end
end
