class OneTimeUtilities

	include Enumerable

	def recalculate_share_prices
		
		# Get each share, along with the previous one as well

		Share.where("id > ?", "30").each do |share|

			last_share = Share.where("id < ?", share.id).order(:id).last

			#Compute based on previous share price not new one!

			# Pull all donations between this and the last share computation
			donations = Donation.where(created_at: (last_share.created_at..share.created_at))
			grants = Grant.where("(status = ? OR status = ?)", 'accepted', 'pending_acceptance').where(created_at: (last_share.created_at..share.created_at))
			share_price = last_share.donation_price

			modifier = 478.02

      current_balance = share.stripe_balance + share.etrade_balance + share.dwolla_balance + share.transit_balance - modifier

			share_total_beginning = share.share_total_beginning

			shares_added_by_donation = donations.sum(:shares_added)

      # shares removed by grant
      shares_subtracted_by_grants = grants.sum(:shares_subtracted)

      share_total_end = BigDecimal(share_total_beginning.to_s) + BigDecimal(shares_added_by_donation.to_s) - BigDecimal(shares_subtracted_by_grants.to_s)

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

  	end
	end

end