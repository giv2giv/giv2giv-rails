class AddStripeCustIdToDonors < ActiveRecord::Migration
  def change
    add_column :donors, :stripe_cust_id, :string
  end
end
