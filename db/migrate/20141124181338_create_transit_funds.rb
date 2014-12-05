class CreateTransitFunds < ActiveRecord::Migration
  def change
    create_table :transit_funds do |t|
    	t.string    :transaction_id, null: false
    	t.string		:source, null: false
    	t.string		:destination, null: false
    	t.decimal   :amount, :precision => 30, :scale => 2, null: false
    	t.boolean   :cleared, default: false
      t.timestamps
    end
  end
end