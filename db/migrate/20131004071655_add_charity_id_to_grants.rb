class AddCharityIdToGrants < ActiveRecord::Migration
  def change
    add_column :grants, :charity_id, :integer
    add_column :grants, :givfee, :float
    add_column :charities, :email, :string
  end
end
