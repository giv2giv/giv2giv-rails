class Share < ActiveRecord::Base
	validates :stripe_balance, :presence => true
	validates :etrade_balance, :presence => true
end