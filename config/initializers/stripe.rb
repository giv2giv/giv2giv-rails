Stripe.api_key = App.stripe["api_key"]

STRIPE_FEES = App.stripe["fees"]
STRIPE_FEES_CENTS = App.stripe["fees_cents"]

StripeEvent.setup do
  subscribe 'charge.succeeded' do |event|
    StripeCallbacks.new.charge_succeeded(event)
  end # end charge.succeeded
end
