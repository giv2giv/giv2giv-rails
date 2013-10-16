class CreateEtradeTable < ActiveRecord::Migration
  def change
    create_table :etrades do |t|
      t.timestamps
      t.datetime :date
      t.decimal :balance, null: false
      t.decimal :fees
    end
  end
end
