class AddAcceptedTermsOnToDonors < ActiveRecord::Migration
  def change
  	add_column :donors, :accepted_terms_on, :datetime, :null => false
  end
end
