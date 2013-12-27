Stripe.api_key = App.stripe["api_key"]

STRIPE_FEES = App.stripe["fees"]
STRIPE_FEES_CENTS = App.stripe["fees_cents"]

StripeEvent.setup do

  subscribe 'charge.succeeded' do |event|

    def net_amount (gross_amount)
      net_amount = (((gross_amount - (gross_amount * STRIPE_FEES)) - STRIPE_FEES_CENTS).to_f * 10).ceil / 10.0
    end

    invoice = event.data.object.invoice
    
    if invoice.blank?    
      ret_invoice = nil
    else
      ret_invoice = Stripe::Invoice.retrieve(invoice)
    end

    if ret_invoice.blank?
      # one-time-payment
      charge_amount = event.data.object.amount / 100
      donation_amount = net_amount(charge_amount)
      transaction_fees = charge_amount - donation_amount

      subscription = DonorSubscription.find_by_stripe_subscription_id(event.data.object.id) # will this work? stripe charge.id
      Donation.add_donation(subscription.id, charge_amount, transaction_fees, donation_amount)

      if donation.save
        donor = Donor.find(subscriptions.first.donor_id)
        DonorMailer.charge_success(donor.email, charge_amount).deliver
      else
        puts "ERROR!"
      end

    else
      # recurring subscriptions
      charge_amount = ret_invoice.lines.data.amount / 100
      donation_amount = net_amount(charge_amount)
      transaction_fees = charge_amount - donation_amount

      subscriptions = DonorSubscription.find_by_stripe_subscription_id(ret_invoice.lines.data.id) # will this work? stripe subscription.id
      subscriptions_gross_amount_sum = subscriptions.sum(gross_amount)

      subscriptions.each do |subscription|
         this_endowment_percentage_of_gross = BigDecimal(subscription.gross_amount) / BigDecimal(subscriptions_gross_amount_sum) # What % is this endowment to all subscribed endowments?

# Should we use BigDecimal here?

         this_endowment_portion_of_charge = (BigDecimal(this_endowment_percentage_of_gross) * BigDecimal(subscription.gross_amount)).round(SHARE_PRECISION) # apply same % to charge 
         this_endowment_portion_of_fees = (BigDecimal(this_endowment_percentage_of_gross) * (BigDecimal(charge_amount) - BigDecimal(donation_amount))).round(SHARE_PRECISION) # apply same % to fees
         this_endowment_portion_of_donation = (BigDecimal(this_endowment_percentage_of_gross) * BigDecimal(donation_amount)).round(SHARE_PRECISION) # apply same % to donation
         Donation.add_donation(subscription.id, this_endowment_portion_of_charge, this_endowment_portion_of_fees, this_endowment_portion_of_donation)
      end

      if donation.save
        donor = Donor.find(subscriptions.first.donor_id)
        DonorMailer.charge_success(donor.email, charge_amount).deliver
      else
        puts "ERROR!"
      end

    end # end else
   
  end # end charge.succeeded
end
