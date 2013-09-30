class AddColumnTypeUserDonors < ActiveRecord::Migration
  def change
    add_column :donors, :type_donor, :string
  end
end
