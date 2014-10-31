class StripeCallbacks

  def charge_succeeded(event)

    invoice = event.data.object.invoice

    if invoice.blank?
      subscription = DonorSubscription.find_by_stripe_subscription_id(event.data.object.id) # stripe charge.id
    else
      invoice = Stripe::Invoice.retrieve(event.data.object.invoice)
      subscription = DonorSubscription.find_by_stripe_subscription_id(invoice.lines.data.first.id) # stripe subscription.id
    end

    transaction = Stripe::BalanceTransaction.retrieve(event.data.object.balance_transaction)

    charge_amount = BigDecimal(transaction.amount.to_s) / 100
    transaction_fee = BigDecimal(transaction.fee.to_s) / 100
    donation_amount = BigDecimal(transaction.net.to_s) / 100
    transaction_id = transaction.id.to_s

    donation = Donation.add_donation(subscription.id, charge_amount, transaction_id, transaction_fee, donation_amount)
    donor = Donor.find(subscription.donor_id)
    DonorMailer.charge_success(donor, charge_amount).deliver

  end

end