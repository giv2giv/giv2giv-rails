class AddLatitudeAndLongitudeToCharity < ActiveRecord::Migration
  def change
    add_column :charities, :latitude, :float
    add_column :charities, :longitude, :float
    add_index :charities, [:latitude, :longitude]
  end
end