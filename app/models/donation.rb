class Donation < ActiveRecord::Base
  belongs_to :payment_account
  belongs_to :charity_group
  belongs_to :donor
  
  with_options :presence => true do |donation|
    donation.validates :gross_amount
  end

  PER_SHARE_DEFAULT = 100000
  STRIPE_FEES = App.stripe["fees"]
  STRIPE_FEES_CENTS = App.stripe["fees_cents"]

  class << self
    
    def add_donation(amount, subs_id)
      
      check_share_price = Share.last
      if check_share_price.blank?
        per_share = PER_SHARE_DEFAULT
      else
        per_share = check_share_price.donation_price
      end

      net_amount = (amount - (amount * STRIPE_FEES)) - STRIPE_FEES_CENTS
      transaction_fee = amount - net_amount

      donor_subs_id = DonorSubscription.find_by_stripe_subscription_id(subs_id)

      buy_shares = (BigDecimal("#{amount}") / BigDecimal("#{per_share}"))
      donation = Donation.new(
                             :gross_amount => amount,
                             :charity_group_id => donor_subs_id.charity_group_id,
                             :payment_account_id => donor_subs_id.payment_account_id,
                             :shares_added => buy_shares,
                             :donor_id => donor_subs_id.donor_id,
                             :transaction_fees => transaction_fee,
                             :net_amount => net_amount
                             )
      if donation.save
        donor = Donor.find(donor_subs_id.donor_id)
        DonorMailer.charge_success(donor.email).deliver
      else
        puts "ERROR!"
      end
    end

  end

end
