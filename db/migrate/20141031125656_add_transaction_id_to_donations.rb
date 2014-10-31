class AddTransactionIdToDonations < ActiveRecord::Migration
  def change
		add_column :donations, :transaction_id, :string
  end
end
