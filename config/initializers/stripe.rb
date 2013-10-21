Stripe.api_key = App.stripe["api_key"]

StripeEvent.setup do
  subscribe 'charge.succeeded' do |event|
    invoice = event.data.object.invoice
    
    if invoice.blank?    
      ret_invoice = nil
    else
      ret_invoice = Stripe::Invoice.retrieve(invoice)
    end


# Buy shares here, split between charity_groups

    if ret_invoice.blank? || ret_invoice.empty?
      stripe_amount = event.data.object.amount / 100

      total_amount = donor.subscriptions.sum(:amount)

      donor.subscriptions.each do |subscription|

        charity_group_percentage = subscription.amount / donor.subscriptions.sum(:amount)
        charity_group_donation_amount = (charity_group_percentage * stripe_amount * 10).ceil / 10

        Donation.add_donation(charity_group_donation_amount, event.data.object.id)  # should this be event.data.id ?

      end


    else
      ret_invoice.lines.data.each do |line_data|
        stripe_amount = line_data.amount / 100

        total_amount = donor.subscriptions.sum(:amount)

        donor.subscriptions.each do |subscription|

          charity_group_percentage = subscription.amount / donor.subscriptions.sum(:amount)
          charity_group_donation_amount = (charity_group_percentage * stripe_amount * 10).ceil / 10

          Donation.add_donation(charity_group_donation_amount, line_data.id)

        end

      end # end each subscription  
    end
    
  end
end
