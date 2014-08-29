class ChangeAcceptedTermsToBoolean < ActiveRecord::Migration
  def up
    change_column :donors, :accepted_terms, :boolean
  end

  def down
    change_column :donors, :accepted_terms, :string
  end
end
