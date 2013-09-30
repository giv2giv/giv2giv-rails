require 'nokogiri'
require 'stripe'
require 'oauth'
include OAuth::Helper

module CalculationShare
  class Calculation

    class << self

      def priceshare
        stripe_balance = get_stripe_balance
        etrade_balance = get_etrade_balance

        givbalance = stripe_balance + etrade_balance
        last_shares = Givshare.group(:donation_id)
        charity_groups = Givshare.group(:charity_group_id)
        
        charity_groups.each do |charity|
          share = 0
          last_shares.each do |donor|
            giv = Givshare.find_by_donor_id(donor.donor_id)
            share += giv.shares_bought_through_donations
          end

          new_share_price = givbalance / share
          
          last_shares.each do |donor|
            donor_new_record = Givshare.where(donation_id: donor.donation_id).last
            new_record_share = Givshare.new(
                        :charity_group_id => charity.charity_group_id,
                        :stripe_balance => stripe_balance,
                        :etrade_balance => etrade_balance,
                        :shares_outstanding_beginning => donor_new_record.shares_outstanding_end,
                        :shares_bought_through_donations => donor_new_record.shares_bought_through_donations,
                        :shares_outstanding_end => share,
                        :donation_price => new_share_price.round(2),
                        :round_down_price => new_share_price,
                        :donor_id => donor_new_record.donor_id,
                        :donation_id => donor_new_record.donation_id
                      )
            new_record_share.save
          end
        end
      end

    private

      def get_stripe_balance
        stripe_balance = Stripe::Balance.retrieve
        return (stripe_balance["pending"][0][:amount].to_f) / 100
      end

      def get_etrade_balance
        etrade_balance = 0
        return etrade_balance
      end

    end # end self
  end
end
