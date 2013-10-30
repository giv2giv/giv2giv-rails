class Donation < ActiveRecord::Base
  belongs_to :payment_account
  belongs_to :endowment
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

      donor_subscription = DonorSubscription.find_by_stripe_subscription_id(subscription_id)

      buy_shares = (BigDecimal("#{net_amount}") / BigDecimal("#{per_share}"))
      donation = Donation.new(
                             :gross_amount => gross_amount,
                             :endowment_id => donor_subscription.endowment_id,
                             :payment_account_id => donor_subscription.payment_account_id,
                             :shares_added => buy_shares,
                             :donor_id => donor_subscription.donor_id,
                             :transaction_fees => transaction_fee,
                             :net_amount => net_amount
                             )

      if donation.save
        donor = Donor.find(donor_subscription.donor_id)
        {"gross_amount" => gross_amount, "email" => donor.email}
      else
        puts "ERROR!"
      end
    end

  end

end
