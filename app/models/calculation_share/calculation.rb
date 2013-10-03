require 'nokogiri'
require 'stripe'
require 'oauth'
include OAuth::Helper

module CalculationShare
  class Calculation

    class << self

      # everyday 00:00:00
      def priceshare
        stripe_balance = get_stripe_balance
        etrade_balance = get_etrade_balance.to_f

        # get charity group balance
        givbalance = stripe_balance + etrade_balance

        # get shares_added_by_donation
        donor_shares = Donation.sum(:shares_added).to_f
        donors_shares_total_beginning = Share.order("created_At DESC").last.share_total_end.to_f rescue 0.0
        share_total_before = Share.order("created_At DESC").last.share_total_beginning.to_f rescue 0.0
        share_total_end = donor_shares + share_total_before

        # get donation share price
        share_price = givbalance / donor_shares

        if share_price.to_f.nan?
          share_price = 100000
        end

        round_up_share_price = (share_price * 10).ceil / 10.0
        grant_amount = (1.25 / 100) * givbalance

        new_record_share = Share.new(
                                     :stripe_balance => stripe_balance,
                                     :etrade_balance => etrade_balance,
                                     :share_total_beginning => donors_shares_total_beginning,
                                     :shares_added_by_donation => donor_shares,
                                     :shares_subtracted_by_grants => grant_amount,
                                     :share_total_end => share_total_end,
                                     :share_price => round_up_share_price
                                    )
        if new_record_share.save
          puts "Share Price has been updated"
        else
          puts "ERROR"
        end        
      end

      # every 90 days
      def grant_to_charities
        stripe_balance = get_stripe_balance
        etrade_balance = get_etrade_balance.to_f
        givbalance = stripe_balance + etrade_balance

        grant = ( 1.25 / 100 ) * givbalance
        givpayment = ( 4 / 100 ) * grant
        
        charity_group_id = Donation.group(:charity_group_id)

        charity_group_id.each do |charity|
          search_charities = CharityGroup.find(charity.charity_group_id)
          charities = search_charities.charities

          grant_amount = (1.25 / 100) * charity_group.Balance
          giv2giv_payment += (4 / 100) * grant_amount

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
