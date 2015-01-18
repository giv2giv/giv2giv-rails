class DropDescriptionRenameLongDescriptionToDescriptionCharities < ActiveRecord::Migration

  def up
    remove_column :charities, :tagline
    remove_column :charities, :short_description
    rename_column :charities, :long_description, :tagline
  end
  def down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    add_column :charities, :tagline, :text
    add_column :charities, :short_description, :text
    rename_column :charities, :tagline, :long_description
  end

end