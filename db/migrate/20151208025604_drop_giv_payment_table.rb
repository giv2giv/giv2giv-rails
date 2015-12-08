class DropGivPaymentTable < ActiveRecord::Migration
	def change
		drop_table :giv_payments do |t|
			t.float :amount
			t.string   "from_etrade_to_dwolla_transaction_id"
	    t.string   "from_dwolla_to_giv2giv_transaction_id"
	    t.string   "status"
	    t.timestamps null: false
	  end
	end
end