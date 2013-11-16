class AddAuthTokenToDonors < ActiveRecord::Migration
  def change
    add_column :donors, :auth_token, :string
  end
end
