class CreateEtradeTable < ActiveRecord::Migration
  def change
    create_table :etrade do |t|
      t.timestamps
      t.datetime :date
      t.float :balance, null: false
      t.float :fees
    end
  end
end
