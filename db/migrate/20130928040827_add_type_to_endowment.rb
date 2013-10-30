class AddTypeToEndowment < ActiveRecord::Migration
  def change
    add_column :endowments, :type_donation, :string
  end
end
