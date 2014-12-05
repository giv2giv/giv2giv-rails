class AddDescriptionsToCharities < ActiveRecord::Migration
  def change
  	add_column :charities, :website, :string
  	add_column :charities, :phone, :string
		add_column :charities, :tagline, :string
		add_column :charities, :short_description, :string
		add_column :charities, :long_description, :text
  end
end