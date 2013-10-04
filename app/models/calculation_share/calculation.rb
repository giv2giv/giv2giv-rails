require 'nokogiri'
require 'stripe'
require 'oauth'
include OAuth::Helper
include EtradeHelper

module CalculationShare
  class Calculation

    class << self

      # everyday 00:00:00
      def priceshare
        stripe_balance = get_stripe_balance
        etrade_balance = get_etrade_balance

        # get charity group balance
        givbalance = stripe_balance + etrade_balance

        # get shares_added_by_donation
        donor_shares_group = Donation.group("date_format(created_at, '%Y%m%d')").sum(:shares_added)
        date_today = Date.yesterday.strftime('%Y%m%d')
        if date_today.eql?(donor_shares_group.keys.last)      
          donor_shares = donor_shares_group.values.last.to_f
        else
          donor_shares = 0.0
        end
        
        donors_shares_total_beginning = Share.order("created_At DESC").last.share_total_end.to_f rescue 0.0
        share_total_before = Share.order("created_At DESC").last.share_total_beginning.to_f rescue 0.0
        share_total_end = donor_shares + share_total_before

        # get donation share price
        share_price = givbalance / share_total_end

        if share_price.to_f.nan?
          share_price = 100000
        end

        round_up_share_price = (share_price * 10).ceil / 10.0
        grant_amount = givbalance * (1.25 / 100) * (96.0 / 100)

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
      def grantshare
        stripe_balance = get_stripe_balance
        etrade_balance = get_etrade_balance

        givbalance = stripe_balance + etrade_balance
        grant_price = Share.last.share_price.round(2) rescue 0.0

        grant_amount = givbalance * (1.25 / 100) * (96.0 / 100)
        giv2giv_fee = givbalance * (1.25 / 100) * (4.0 / 100)
        total_amount_and_fee = givbalance * (1.25 / 100)

        all_charity_group_balance = givbalance
  
        charity_groups = CharityGroup.all
        charity_groups.each do |charity_group|
          giv2giv_fee = giv2giv_fee + (charity_group.donations.sum(:amount) - (charity_group.donations.sum(:amount) * 2.9 / 100)) * (1.25 / 100) * (4.0 / 100)
          charitygroup_total_grant = (charity_group.donations.sum(:amount) - (charity_group.donations.sum(:amount) * 2.9 / 100)) * (1.25 / 100) * (96.0 / 100)

          charities = charity_group.charities
          charities.each do |charity|
            grant_charity = charity
            grant_amount_charity = charitygroup_total_grant / charity_group.charities.count
            grant_charity_donor = charity_group.donor_id
            grant_charity_group = charity_group.id
            grant_shares_sold = grant_amount_charity / grant_price

            grant_record = Grant.new(:donor_id => grant_charity_donor, :charity_group_id => grant_charity_group, :date => Date.today, :shares_subtracted => grant_shares_sold, :charity_id => charity.id, :givfee => giv2giv_fee)
            grant_record.save
          end # end charities
        end # end charity_groups
      end

      #close issue #7
      def cumulative_etrade_balance(account_id)
        Etrade.update_balance(account_id)
      end

    private
     
      def get_stripe_balance
        stripe_balance = Stripe::Balance.retrieve
        stripe_pending = (stripe_balance["pending"][0][:amount].to_f) / 100
        stripe_available = (stripe_balance["available"][0][:amount].to_f) / 100
        total_stripe = stripe_pending + stripe_available
      end

      def get_etrade_balance
        if Rails.env.eql?("production")
          etrade_balance = Etrade.get_net_account_value rescue 0.0
        else
          etrade_balance = 0.0
        end
        return etrade_balance.to_f
      end

    end # end self
  end
end
