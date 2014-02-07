class StripeCallbacks

  SHARE_PRECISION = App.giv["share_precision"]


  def process_one_time_payment(event)
    
    transaction = Stripe::BalanceTransaction.retrieve(event.data.object.balance_transaction)
    subscription = DonorSubscription.find_by_stripe_subscription_id(event.data.object.id) # stripe charge.id

    charge_amount = BigDecimal(transaction.amount.to_s) / 100
    transaction_fee = BigDecimal(transaction.fee.to_s) / 100
    donation_amount = BigDecimal(transaction.net.to_s) / 100

    donation = Donation.add_donation(subscription.id, charge_amount, transaction_fee, donation_amount)

    if !donation.save
      puts "ERROR!" # TODO: better error handling
      return
    end

    donor = Donor.find(subscription.donor_id)
    DonorMailer.charge_success(donor.email, charge_amount).deliver

  end

  def process_recurring_payment(event)

    invoice = Stripe::Invoice.retrieve(event.data.object.invoice)
    transaction = Stripe::BalanceTransaction.retrieve(event.data.object.balance_transaction)

    charge_amount = BigDecimal(transaction.amount.to_s) / 100
    transaction_fee = BigDecimal(transaction.fee.to_s) / 100
    donation_amount = BigDecimal(transaction.net.to_s) / 100

    subscription = DonorSubscription.find_by_stripe_subscription_id(invoice.lines.data.first.id) # stripe subscription.id

    donation = Donation.add_donation(subscription.id, charge_amount, transaction_fee, donation_amount)

    if !donation.save
      puts "ERROR!" # TODO: better error handling
      return
    end

    donor = Donor.find(subscription.donor_id)
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
      Rails.logger.debug "Processing one-time"
    	process_one_time_payment(event)

    else
      Rails.logger.debug "Processing recurring"
    	process_recurring_payment(event)
    end # end else
   
	end
end
