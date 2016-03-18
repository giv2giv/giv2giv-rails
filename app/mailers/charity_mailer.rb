class CharityMailer < BaseMailer
	def endowment_grant_issued(charity, amount)
	    subject = "giv2giv Grant Disbursement"
	    endowment = Endowment.find(charity.main_endowment_id)
	    website_address = build_url(endowment)

	    merge_vars = {
	      "NAME" => charity.name,
	      "EIN" => charity.ein,
	      "AMOUNT" => amount,
	      "CHARITY_WEBSITE" => website_address
	    }
	    send_mandrill(donor, subject, merge_vars, 'endowment_grant_issued')
	end

	def endowment_grant_held(charity)
	    subject = "Information about your giv2giv Grant"
	    endowment = Endowment.find(charity.main_endowment_id)
	    website_address = build_url(endowment)

	    merge_vars = {
	      "NAME" => charity.name,
	      "EIN" => charity.ein,
				"MINIMUM_GRANT" => ActionController::Base.helpers.number_to_currency(App.giv['minimum_grant_amount']),	      
	      "CHARITY_WEBSITE" => website_address
	    }
	    send_mandrill(donor, subject, merge_vars, 'endowment_grant_held')
	end
end
