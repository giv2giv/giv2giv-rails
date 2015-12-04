class StripeCallbacks

  def charge_succeeded(event)

    invoice = event.data.object.invoice

    if invoice.blank?
      subscription = DonorSubscription.find_by unique_subscription_id: event.data.object.id

    else
      invoice = Stripe::Invoice.retrieve(event.data.object.invoice)
      subscription = DonorSubscription.find_by unique_subscription_id: invoice.lines.data.first.id
    end

    transaction = Stripe::BalanceTransaction.retrieve(event.data.object.balance_transaction)

    charge_amount = BigDecimal(transaction.amount.to_s) / 100
    transaction_fee = BigDecimal(transaction.fee.to_s) / 100
    donation_amount = BigDecimal(transaction.net.to_s) / 100
    transaction_id = transaction.id.to_s

    donation = Donation.add_donation(subscription, charge_amount, transaction_id, transaction_fee, donation_amount)
    
    Grant.add_passthru_grant(subscription, donation_amount)

    donor = Donor.find(subscription.donor_id)
    endowment = Endowment.find(subscription.endowment_id)

    DonorMailer.widget_donor_thankyou(donor, endowment, charge_amount)

    if endowment.charities.count==1 && endowment.charities.first.email && donor.share_info? && !(donor.email.include? "giv2giv.org")
      DonorMailer.charity_donation_notification(endowment.charities.first, donor, endowment, charge_amount).deliver
    elsif endowment.charities.count==1 && endowment.charities.first.email
      DonorMailer.charity_anonymous_donation_notification(endowment.charities.first, endowment, charge_amount).deliver
    end

  end

  def card_denied(event)
    p=PaymentAccount.find(event)
    p.requires_reauth=true
    p.save!
    p.sendUpdatePaymentAccountEmail
  end

  def transfer_created(event)
    transfer = event.data.object
    Rails.logger.debug transfer
    TransitFund.create!(
      transaction_id: transfer.id,
      source: "stripe",
      destination: "etrade",
      amount: (BigDecimal("#{transfer.amount}")/100).floor(2), #stripe records cents, we record BigDecimal
      cleared: false
    )
    
  end
  
  def transfer_paid(event)
    transfer = event.data.object
    Rails.logger.debug transfer
    our_transfer = TransitFund.where("transaction_id=?", transfer.id)
    our_transfer.cleared=true
    our_transfer.save!
  end
  
end
