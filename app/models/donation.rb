class Donation < ActiveRecord::Base
  belongs_to :payment_account
  belongs_to :endowment
  belongs_to :donor
  
  with_options :presence => true do |donation|
    donation.validates :gross_amount
  end

  class << self
    
    def add_donation(subscription_id, gross_amount, transaction_fees, net_amount)
      
      share_price = Share.last.donation_price

      donor_subscription = DonorSubscription.find(subscription_id)

      buy_shares = (BigDecimal("#{net_amount}") / BigDecimal("#{share_price}"))
      donation = Donation.new(
                             :donor_id => donor_subscription.donor_id,
                             :endowment_id => donor_subscription.endowment_id,
                             :payment_account_id => donor_subscription.payment_account_id,
                             :gross_amount => gross_amount,
                             :transaction_fees => transaction_fees,
                             :net_amount => net_amount,
                             :shares_added => buy_shares
                             )
      return donation
    end

  end

end
