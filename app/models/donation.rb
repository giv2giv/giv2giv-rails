class Donation < ActiveRecord::Base
  belongs_to :payment_account
  belongs_to :endowment
  belongs_to :donor
  
  with_options :presence => true do |donation|
    donation.validates :gross_amount
  end

  class << self
    
    def add_donation(subscription_id, gross_amount, transaction_id, transaction_fee, net_amount)
      
      share_price = Share.last.donation_price

      donor_subscription = DonorSubscription.find(subscription_id)

      buy_shares = (BigDecimal("#{net_amount}") / BigDecimal("#{share_price}"))

      Donation.where(:donor_id => donor_subscription.donor_id, :transaction_id => transaction_id, :gross_amount => gross_amount).first_or_initialize { |donation|
        donation.donor_id=donor_subscription.donor_id
        donation.endowment_id=donor_subscription.endowment_id
        donation.charity_id=donor_subscription.charity_id
        donation.payment_account_id=donor_subscription.payment_account_id
        donation.transaction_fee=transaction_fee
        donation.net_amount=net_amount
        donation.shares_added=buy_shares
        donation.save!
      }
    end
  end
end
