Stripe.api_key = App.stripe["api_key"]

StripeEvent.setup do
  subscribe 'charge.succeeded' do |event|
    # event.data.object.amount <= get amount
    # event.data.object.id <= charge id
    cust_id = PaymentAccount.find_by_stripe_cust_id(event.data.object.customer)
    donor = Donor.find(cust_id.donor_id)
    DonorMailer.charge_success(donor.email).deliver
  end
end