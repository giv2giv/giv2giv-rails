class DropDescriptionRenameLongDescriptionToDescriptionCharities < ActiveRecord::Migration

  def up
    remove_column :charities, :description
    rename_column :charities, :long_description, :description
  end
  def down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    rename_column :charities, :description, :long_description
    add_column :charities, :description, :text
  end

end