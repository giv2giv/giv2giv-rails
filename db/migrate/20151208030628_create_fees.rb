class CreateFees < ActiveRecord::Migration
  def change
    create_table :fees do |t|
      t.decimal :shares_outstanding, precision: 30, scale: 20, null: false
      t.decimal :shares_subtracted, precision: 30, scale: 20, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string  :transaction_id
      t.boolean :cleared, default: false
      t.timestamps
    end
  end
end
