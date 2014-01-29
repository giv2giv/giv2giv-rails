class StripeCallbacks

  SHARE_PRECISION = App.giv["share_precision"]

  def net_amount (gross_amount)
    (((gross_amount - (gross_amount * STRIPE_FEES)) - STRIPE_FEES_CENTS).to_f * 10).ceil / 10.0
  end

  def process_one_time_payment(event)
    # TODO this needs updating - can it be the same as process_recurring?

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

  def process_recurring_payment(event)

    invoice = Stripe::Invoice.retrieve(event.data.object.invoice)

    transaction = Stripe::BalanceTransaction.retrieve(event.data.object.balance_transaction)

    charge_amount = transaction.amount
    donation_amount = transaction.net
    transaction_fee = transaction.fee

    percent_net = BigDecimal(donation_amount.to_s) / BigDecimal(charge_amount.to_s)

    subscriptions = DonorSubscription.where(stripe_subscription_id: invoice.lines.data.first.id) # will this work? stripe subscription.id

    subscriptions_gross_amount_sum = subscriptions.sum(:gross_amount)

    subscriptions.each do |subscription|

       this_endowment_percentage_of_gross = BigDecimal(subscription.gross_amount.to_s) / BigDecimal(charge_amount.to_s)
       this_endowment_transaction_fees = (BigDecimal(this_endowment_percentage_of_gross.to_s) * BigDecimal(transaction_fee.to_s)).round(SHARE_PRECISION)
       this_endowment_donation = (BigDecimal(this_endowment_percentage_of_gross.to_s) * BigDecimal(donation_amount.to_s)).round(SHARE_PRECISION)

       donation = Donation.add_donation(subscription.id, subscription.gross_amount, this_endowment_transaction_fees, this_endowment_donation)

       if !donation.save
	       puts "ERROR!" # TODO: better error handling
	       return
       end
    end

    donor = Donor.find(subscriptions.first.donor_id)
    DonorMailer.charge_success(donor.email, charge_amount/100).deliver
  end


	def charge_succeeded(event)
    invoice = event.data.object.invoice
    
    if invoice.blank?    
      ret_invoice = nil
    else
      ret_invoice = Stripe::Invoice.retrieve(invoice)
    end

    if ret_invoice.blank?
      Rails.logger.debug "Processing one-time"
    	process_one_time_payment(event)

    else
      Rails.logger.debug "Processing recurring"
    	process_recurring_payment(event)
    end # end else
   
	end
end
