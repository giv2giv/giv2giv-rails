require 'nokogiri'
require 'stripe'
require 'oauth'
include OAuth::Helper

module CalculationShare
  class Calculation

    class << self

      def priceshare
        # stripe_balance = get_stripe_balance
        # etrade_balance = get_etrade_balance

        stripe_balance = 25
        etrade_balance = 0
        etrade_adjustment = 5

        givbalance = stripe_balance + etrade_balance

        last_shares = Givshare.group(:donation_id)
        charity_groups = Givshare.group(:charity_group_id)
        
        charity_groups.each do |charity|
          share = 0
          last_shares.each do |donor|
            giv = Givshare.find_by_donor_id(donor.donor_id)
            share += giv.shares_bought_through_donations
          end

          new_donation_share_price = givbalance / share

          last_shares.each do |donor|
           
            donor_new_record = Givshare.where(donation_id: donor.donation_id).last
            shared_donated = Donation.find(donor_new_record.donation_id).amount

            share_donated = shared_donated.to_f / donor_new_record.donation_price.to_f
            share_total_before = Givshare.where(donation_id: donor.donation_id).offset(donor_new_record.count).first.share_total rescue 0
            share_total = share_total_before + donor_new_record.shares_bought_through_donations
            charity_group_balance = share_total.to_f * donor_new_record.donation_price.to_f * (1 + (etrade_adjustment.to_f / 100).to_f).to_f

            new_record_share = Givshare.new(
                        :charity_group_id => charity.charity_group_id,
                        :stripe_balance => stripe_balance,
                        :etrade_balance => etrade_balance,
                        :shares_outstanding_beginning => donor_new_record.shares_outstanding_end,
                        :shares_bought_through_donations => share_donated,
                        :shares_outstanding_end => share,
                        :donation_price => (new_donation_share_price * 10).ceil / 10.0,
                        :round_down_price => new_donation_share_price.round(2),
                        :donor_id => donor_new_record.donor_id,
                        :donation_id => donor_new_record.donation_id,
                        :share_total => share_total,
                        :share_granted => 0,
                        :donor_grant => 0,
                        :is_grant => 0,
                        :etrade_adjustment => etrade_adjustment,
                        :charity_group_balance => charity_group_balance.to_f,
                        :count => donor_new_record.count + 1
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
