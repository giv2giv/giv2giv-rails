Stripe.api_key = App.stripe["api_key"]

StripeEvent.setup do
  subscribe 'charge.succeeded' do |event|
    invoice = event.data.object.invoice
    
    if invoice.blank?    
      ret_invoice = nil
    else
      ret_invoice = Stripe::Invoice.retrieve(invoice)
    end

    if ret_invoice.blank? || ret_invoice.empty?
      amount = event.data.object.amount / 100
      Donation.add_donation(amount, event.data.object.id)
    else
      ret_invoice.lines.data.each do |line_data|
        amount = line_data.amount / 100
        Donation.add_donation(amount, line_data.id)
      end # end each subscription  
    end
    
  end
end