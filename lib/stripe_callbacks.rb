class StripeCallbacks

  def net_amount (gross_amount)
    (((gross_amount - (gross_amount * STRIPE_FEES)) - STRIPE_FEES_CENTS).to_f * 10).ceil / 10.0
  end

  def process_one_time_payment(event)
    charge_amount = event.data.object.amount / 100
    donation_amount = net_amount(charge_amount)
    transaction_fees = charge_amount - donation_amount

    subscription = DonorSubscription.find_by_stripe_subscription_id(event.data.object.id) # will this work? stripe charge.id
    donation = Donation.add_donation(subscription.id, charge_amount, transaction_fees, donation_amount)

    if donation.save
      donor = Donor.find(subscriptions.first.donor_id)
      DonorMailer.charge_success(donor.email, charge_amount).deliver
    else
      puts "ERROR!"
    end
  end

  def process_recurring_payment(event, invoice)
    charge_amount = invoice.lines.data.first.amount / 100
    donation_amount = net_amount(charge_amount)
    transaction_fees = charge_amount - donation_amount

    subscriptions = DonorSubscription.where(stripe_subscription_id: invoice.lines.data.first.id) # will this work? stripe subscription.id
    subscriptions_gross_amount_sum = subscriptions.sum(:gross_amount)

    subscriptions.each do |subscription|
       this_endowment_percentage_of_gross = BigDecimal(subscription.gross_amount.to_s) / BigDecimal(subscriptions_gross_amount_sum.to_s) # What % is this endowment to all subscribed endowments?

# Should we use BigDecimal here?

       this_endowment_portion_of_charge = (BigDecimal(this_endowment_percentage_of_gross.to_s) * BigDecimal(subscription.gross_amount.to_s)).round(SHARE_PRECISION) # apply same % to charge 
       this_endowment_portion_of_fees = (BigDecimal(this_endowment_percentage_of_gross.to_s) * (BigDecimal(charge_amount.to_s) - BigDecimal(donation_amount.to_s))).round(SHARE_PRECISION) # apply same % to fees
       this_endowment_portion_of_donation = (BigDecimal(this_endowment_percentage_of_gross.to_s) * BigDecimal(donation_amount.to_s)).round(SHARE_PRECISION) # apply same % to donation
       donation = Donation.add_donation(subscription.id, this_endowment_portion_of_charge, this_endowment_portion_of_fees, this_endowment_portion_of_donation)

       if !donation.save
	       puts "ERROR!" # TODO: better error handling
	       return
       end
    end

    donor = Donor.find(subscriptions.first.donor_id)
    DonorMailer.charge_success(donor.email, charge_amount).deliver
  end

	def charge_succeeded(event)
    invoice = event.data.object.invoice
    
    if invoice.blank?    
      ret_invoice = nil
    else
      ret_invoice = Stripe::Invoice.retrieve(invoice)
    end

    if ret_invoice.blank?
    	process_one_time_payment(event)

    else
    	process_recurring_payment(event, ret_invoice)
    end # end else
   
	end
end