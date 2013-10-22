class Donation < ActiveRecord::Base
  belongs_to :payment_account
  belongs_to :charity_group
  belongs_to :donor
  
  with_options :presence => true do |donation|
    donation.validates :gross_amount
  end

  PER_SHARE_DEFAULT = 100000.0
  STRIPE_FEES = App.stripe["fees"]
  STRIPE_FEES_CENTS = App.stripe["fees_cents"]

  class << self
    
    def add_donation(gross_amount, subscription_id)
      
      check_share_price = Share.last
      if check_share_price.blank?
        per_share = PER_SHARE_DEFAULT
      else
        per_share = check_share_price.donation_price
      end

      net_amount = (gross_amount - (gross_amount * STRIPE_FEES)) - STRIPE_FEES_CENTS
      transaction_fee = gross_amount - net_amount

      donor_subscription_id = DonorSubscription.find_by_stripe_subscription_id(subscription_id)

      buy_shares = (BigDecimal("#{net_amount}") / BigDecimal("#{per_share}"))
      donation = Donation.new(
                             :gross_amount => gross_amount,
                             :charity_group_id => donor_subscription_id.charity_group_id,
                             :payment_account_id => donor_subscription_id.payment_account_id,
                             :shares_added => buy_shares,
                             :donor_id => donor_subscription_id.donor_id,
                             :transaction_fees => transaction_fee,
                             :net_amount => net_amount
                             )

# ELGA  if in config/initializers/stripe.rb we foreach (donor.giv2giv_subscriptions)    then only send ONE email for stripe.charge_success
      if donation.save
        donor = Donor.find(donor_subscription_id.donor_id)
        DonorMailer.charge_success(donor.email, CharityGroup.find(charity_group_id).name, gross_amount).deliver
      else
        puts "ERROR!"
      end
    end

  end

end
