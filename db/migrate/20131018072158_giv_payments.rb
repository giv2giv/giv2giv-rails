class GivPayments < ActiveRecord::Migration
  def change
    create_table :giv_payments do |t|
      t.integer :dwolla_transaction_id
      t.float :amount
      t.timestamps
    end
  end
end
