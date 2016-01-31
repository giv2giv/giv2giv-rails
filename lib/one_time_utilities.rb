class OneTimeUtilities

	include Enumerable

	def recalculate_share_prices
		
		# Get each share, along with the next one as well

		Share.where("created_at > ?", "2015-06-01").each do |share|

			next_share = Share.where("id > ?", share.id).order(:id).first

			if next_share.nil?
				next_share = Share.new
				next_share.created_at = DateTime.new(2100,1,1)
			end

			modifier = 0
			# Pull all donations between this and the next share computation
			donations = Donation.where(created_at: (share.created_at..next_share.created_at))
			grants = Grant.where("(status = ? OR status = ?)", 'accepted', 'pending_acceptance').where(created_at: (share.created_at..next_share.created_at))
			fees = Fee.where(created_at: (share.created_at..next_share.created_at))

			if share.created_at > DateTime.new(2015,9,2)
				modifier = 478.02
			end

      current_balance = share.stripe_balance + share.etrade_balance + share.dwolla_balance + share.transit_balance - modifier

			share_total_beginning = share.share_total_beginning

			shares_added_by_donation = donations.sum(:shares_added)

      # shares removed by grant
      shares_subtracted_by_grants = grants.sum(:shares_subtracted)

      # shares removed by fees
      shares_subtracted_by_fees = fees.sum(:shares_subtracted)

      share_total_end = (BigDecimal(share_total_beginning.to_s) + BigDecimal(shares_added_by_donation.to_s) - BigDecimal(shares_subtracted_by_grants.to_s) - BigDecimal(shares_subtracted_by_fees.to_s))

      # get donation share price
      # current_balance / shares_outstanding
      preliminary_share_price = (BigDecimal(current_balance.to_s) / BigDecimal(share_total_end.to_s)).to_f

      preliminary_share_price = 100000.0 unless preliminary_share_price.finite?
      if preliminary_share_price.to_f.nan?
        preliminary_share_price = 100000.0
      end

			#Update the share price
      share.donation_price = preliminary_share_price.ceil2(2)
      share.grant_price = preliminary_share_price.floor2(2)
      share.save!

      #Update each donation transacted based on new share price
			donations.each do |donation|
				donation.shares_added = BigDecimal(donation.net_amount.to_s) / share.donation_price
				donation.save!
			end
			#Update each grant transacted based on new share price
			grants.each do |grant|
				grant.shares_subtracted = BigDecimal(grant.net_amount.to_s) / share.grant_price
				grant.save!
			end

			#No fees exist at time of authorship 

			donations.reload
			grants.reload

			shares_added_by_donation = donations.sum(:shares_added)

      # shares removed by grant
      shares_subtracted_by_grants = grants.sum(:shares_subtracted)


			# Update share end/beginning values
			share.share_total_end = share.share_total_beginning + shares_added_by_donation - shares_subtracted_by_grants
			share.shares_added_by_donation = shares_added_by_donation
			share.shares_subtracted_by_grants = shares_subtracted_by_grants
			share.shares_subtracted_by_fees = 0

if share.id==18
	ap share
end
			share.save!
if share.id==18
	ap share
end
			next_share.share_total_beginning = share.share_total_end

			if next_share.persisted?
  			next_share.save!
  		end
  	end
	end

end