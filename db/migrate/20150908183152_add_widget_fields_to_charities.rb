class AddWidgetFieldsToCharities < ActiveRecord::Migration
  def change
    add_column :charities, :theme, :string, :default=>"flick"
    add_column :charities, :minimum_amount, :integer, :default=>10
    add_column :charities, :maximum_amount, :integer, :default=>10000
    add_column :charities, :minimum_passthru_percentage, :integer, :default=>0
    add_column :charities, :maximum_passthru_percentage, :integer, :default=>100
    add_column :charities, :initial_amount, :integer, :default=>25
    add_column :charities, :initial_passthru, :integer, :default=>50
    add_column :charities, :donors_add_fees, :boolean, :default=>true
  end
end
