class AddColumnTransactionTypeToDonations < ActiveRecord::Migration
  def change
    add_column :donations, :transaction_type, :string
    add_column :donations, :stripe_token, :string
  end
end
