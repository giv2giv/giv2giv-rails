Stripe.api_key = App.stripe["api_key"]
STRIPE_PUBLIC_KEY = App.stripe["publishable_key"]

StripeEvent.setup do
  subscribe 'charge.succeeded' do |event|
    cust_id = Donation.find_by_cust_id(event.data.object.customer)
    payment_id = PaymentAccount.find_by_id(cust_id.payment_account_id)
    donor = Donor.find_by_id(payment_id.donor_id)
    DonorMailer.charge_success(donor.email).deliver
  end
end