class AddPasswordResetTokenToDonors < ActiveRecord::Migration
  def change
    add_column :donors, :password_reset_token, :string
    add_column :donors, :expire_password_reset, :datetime
  end
end
