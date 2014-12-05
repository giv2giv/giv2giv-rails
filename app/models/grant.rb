class Grant < ActiveRecord::Base
  belongs_to :charity
  belongs_to :endowment
  belongs_to :donor
  has_one 	 :fee

  VALID_STATUS = %w(pending_approval denied pending_acceptance accepted reclaimed failed canceled)
  VALID_TYPES = %w(endowed pass_thru)
  validates :status, :presence => true, :inclusion => { :in => VALID_STATUS }
  validates :type, :presence => true, :inclusion => { :in => VALID_TYPES }

  SHARE_PRECISION = App.giv["share_precision"]
	GIV2GIV_PASSTHRU_FEE = App.giv["giv_passthru_fee_amount"]


  def add_passthru_grant (subscription, original_donation_amount)
  	#Called upon successful donation. Sells shares, makes grants to recipient charities

  	grantee_charities = Endowment.find(subscription.endowment_id).charities || return

		share_price = Shares.last.grant_share_price

		grant_amount = (original_donation_amount / 2).floor2(2) # only pass-thru 50%

		giv2giv_fee = (grant_amount * GIV2GIV_PASSTHRU_FEE).floor(2)

  	donation_amount = (original_donation_amount - giv2giv_fee).floor2(2)

 		amount_per_charity = (donation_amount / grantee_charities.count).floor2(2)

 		shares_per_charity = BigDecimal("#{original_donation_amount}") / share_price # BigDecimal/BigDecimal

		ActiveRecord::Base.transaction do
			grants_array = []

	 		grantee_charities.each do |charity|
	 			grant = Grant.new(
	 								:charity_id => charity.id,
	 								:endowment_id => subscription.endowment_id,
	 								:donor_id => subscription.donor_id,
	 								:shares_subtracted => shares_per_charity,
                  :grant_amount => amount_per_charity,
                  :giv2giv_fee => giv2giv_fee,
                  :type => 'pass_thru',
	 								:status => 'pending_approval'
	 								)
	 			if grant.save
	 				grants_array << grant
	 				total_grants += grant.grant_amount
	 			end
	 		end

	 		rounding_leftovers = donation_amount-total_grants

	 		Grant.process_passthru_grants(grants_array, rounding_leftovers)

	 	end

  end

  def process_passthru_grants(grants_array, rounding_leftovers)

  	text = "Hi! This is an unrestricted grant from donors at the crowd-endowment service giv2giv.org  Contact hello@giv2giv.org with any questions or to find out how to partner with us."
  
  	grants_array.each do |grant|
  		charity = Charity.find(grant.charity_id)
  		charity.email || return

      net_amount = grant.grant_amount - grant.giv2giv_fee

  		transaction_id = DwollaLibs.new.dwolla_send(charity.email, text, net_amount)
      transaction_details = DwollaLibs.new.get_detail_transaction(transaction_id)

      if transaction_id.is_a? Integer
      	grant.transaction_id=transaction_id
				grant.transaction_fee=transaction_details.fee
				grant.net_amount = net_amount
      	grant.status='pending_acceptance'
        if grant.save
          # Create funds in-transit record for etrade-to-dwolla
          TransitFund.create(
            transaction_id: transaction.id,
            source: "etrade",
            destination: "dwolla",
            amount: net_amount,
            cleared: false
          )

        end
      else
        ap transaction_id
      end
    end #grants_array.each
  end

  def process_others(giv2giv_fee, rounding_leftovers)
  	#do something (matching donations pot?) with the leftovers
  end

end