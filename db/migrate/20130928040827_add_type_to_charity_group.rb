class AddTypeToCharityGroup < ActiveRecord::Migration
  def change
    add_column :charity_groups, :type_donation, :string
  end
end
