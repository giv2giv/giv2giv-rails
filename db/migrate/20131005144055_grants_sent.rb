class GrantsSent < ActiveRecord::Migration
  def change
    create_table :sent_grants do |t|
      t.date :date
      t.integer :charity_id
      t.integer :dwolla_transaction_id
      t.decimal :amount
      t.decimal :fee
      t.timestamps
    end
  end
end
