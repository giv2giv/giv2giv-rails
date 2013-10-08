require 'nokogiri'
require 'stripe'
require 'oauth'
include OAuth::Helper
include EtradeHelper

GIV_FEE_AMOUNT = 1 - App.giv["giv_fee_percentage"].to_f
GIV_GRANT_AMOUNT = App.giv["giv_grant_amount"]
# CHECK_AMOUNT_MINIMAL = 0.01 / 100

module CalculationShare
  class Calculation

    class << self

      # everyday 00:00:00
      def priceshare
        stripe_balance = get_stripe_balance
        etrade_balance = get_etrade_balance

        if Rails.env.eql?("production")
          givbalance = stripe_balance + etrade_balance
        else
          givbalance = 20.0
        end

        date_yesterday = Date.yesterday.strftime('%Y%m%d')
        date_today = Date.today.strftime('%Y%m%d')

        # shares added by donation
        shares_donated_today = Donation.where("date_format(created_at, '%Y%m%d') = '#{date_today}'").sum(:shares_added)
        shares_donated_yesterday = Donation.where("date_format(created_at, '%Y%m%d') = '#{date_yesterday}'").sum(:shares_added)

        # shares removed by grant
        shares_granted_today = Grant.where("date_format(created_at, '%Y%m%d') = '#{date_today}'").sum(:shares_subtracted)
        shares_granted_yesterday = Grant.where("date_format(created_at, '%Y%m%d') = '#{date_yesterday}'").sum(:shares_subtracted)

        donors_shares_total_beginning = Share.order("created_At DESC").last.share_total_end.to_f rescue 0.0

        share_total_end = donors_shares_total_beginning + shares_donated_yesterday - shares_donated_today - shares_granted_yesterday + shares_granted_today

        # share_total_end = shares_donated_today - shares_granted_yesterday + shares_granted_today

        # get donation share price
        # givbalance / total_donor_shares_all_time
        share_price = givbalance / share_total_end 
        share_price = 100000.0 unless share_price.finite?
        if share_price.to_f.nan?
          share_price = 100000.0
        end

        donation_share_price = (share_price * 10).ceil / 10.0
        grant_share_price = (share_price * 10).floor / 10.0
        
        new_record_share = Share.new(
                                     :stripe_balance => stripe_balance,
                                     :etrade_balance => etrade_balance,
                                     :share_total_beginning => donors_shares_total_beginning,
                                     :shares_added_by_donation => shares_donated_yesterday,
                                     :shares_subtracted_by_grants => shares_granted_yesterday,
                                     :share_total_end => share_total_end,
                                     :donation_price => donation_share_price,
                                     :grant_price => grant_share_price,
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

        if Rails.env.eql?("production")
          givbalance = stripe_balance + etrade_balance
        else
          givbalance = 20.0
        end

        grant_price = Share.last.donation_price rescue 0.0

        giv2giv_fee = givbalance * (GIV_GRANT_AMOUNT) * (GIV_FEE_AMOUNT)

        charity_groups = CharityGroup.all

        charity_groups.each do |charity_group|

          charity_group_share_balance = charity_group.donations.sum(:shares_added) - charity_group.grants.sum(:shares_subtracted)

          charity_group_gross_grant_amount = charity_group_share_balance * GIV_GRANT_AMOUNT

          charity_group_fee = charity_group_gross_grant_amount * GIV_FEE_AMOUNT

          charitygroup_grant = charity_group_gross_grant_amount - charity_group_fee

          charities = charity_group.charities
          charities.each do |charity|
            grant_charity = charity
            grant_amount_charity = charitygroup_grant / charity_group.charities.count
            grant_charity_donor = charity_group.donor_id
            grant_charity_group = charity_group.id
            grant_shares_sold = grant_amount_charity / grant_price

            # if grant_amount_charity > CHECK_AMOUNT_MINIMAL
              if charity.status.eql?("active")
                grant_record = Grant.new(
                                        :donor_id => grant_charity_donor, 
                                        :charity_group_id => grant_charity_group, 
                                        :date => Date.today, 
                                        :shares_subtracted => charitygroup_grant, 
                                        :charity_id => charity.id, 
                                        :giv2giv_total_grant_fee => giv2giv_fee
                                        )
                grant_record.save
              end
            # end # end grant_amount_charity
          end # end charities
        end # end charity_groups
      end

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
