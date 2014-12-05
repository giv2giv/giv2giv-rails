class ChangeCharityDescriptionToText < ActiveRecord::Migration


  def up
    change_column :endowments, :description, :text
  end
  def down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    change_column :endowments, :description, :string
  end

end
