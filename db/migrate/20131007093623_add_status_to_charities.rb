class AddStatusToCharities < ActiveRecord::Migration
  def change
    add_column :charities, :status, :string
  end
end