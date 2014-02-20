class AddAcceptedTermsToDonors < ActiveRecord::Migration
  def change
    add_column :donors, :accepted_terms, :boolean, :null => false
  end
end