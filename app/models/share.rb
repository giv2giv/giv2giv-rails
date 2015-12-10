class Share < ActiveRecord::Base
	validates :stripe_balance, :presence => true
	validates :etrade_balance, :presence => true

	def fee_price
		self.grant_price
	end

	class << self
		def shares_outstanding(datetime=nil)
			if datetime.nil?
				datetime=Time.now
			end
			d=Donation.where("created_at <= ?", datetime).sum(:shares_added)
			g=Grant.where("created_at <= ? AND (status = ? OR status = ?)", datetime, "accepted", "pending_acceptance").sum(:shares_subtracted)
			f=Fee.where("created_at <= ?", datetime).sum(:shares_subtracted)
			d-g-f
		end
	end

end