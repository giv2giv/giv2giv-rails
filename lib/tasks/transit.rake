namespace :transit do

  # bundle exec rake transit:send_stripe_funds
  desc 'Transmit funds from stripe to eTrade via stripe_helper'
  task :send_stripe_funds => :environment do
    include StripeHelper
    Stripe.send_funds_to_etrade
  end

end