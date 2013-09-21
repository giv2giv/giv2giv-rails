class ChangeTransactionIdDonations < ActiveRecord::Migration
  def change
    change_column :donations, :transaction_id, :string, :null => true
  end
end
