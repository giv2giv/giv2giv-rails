class AddGrantThresholdToCharities < ActiveRecord::Migration
  def change
    add_column :charities, :grant_threshold, :integer, :default=>20
  end
end
