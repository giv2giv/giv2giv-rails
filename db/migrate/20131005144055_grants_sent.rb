class GrantsSent < ActiveRecord::Migration
  def change
    create_table :grants_sent do |t|
      t.date :date
      t.integer :charity_id
      t.integer :dwolla_transaction_id
      t.float :amount
      t.float :fee
      t.timestamps
    end
  end
end
