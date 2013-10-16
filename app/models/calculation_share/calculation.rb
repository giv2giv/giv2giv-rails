require 'nokogiri'
require 'stripe'
require 'oauth'
include OAuth::Helper
include EtradeHelper

GIV_FEE_AMOUNT = 1 - App.giv["giv_fee_percentage"].to_f
GIV_GRANT_AMOUNT = App.giv["giv_grant_amount"]
SHARE_PRECISION = App.giv["share_precision"]

module CalculationShare
  class Calculation

    class << self

      def priceshare
        # stripe_balance = get_stripe_balance
        # etrade_balance = get_etrade_balance
        # givbalance = stripe_balance + etrade_balance
        
        givbalance = 20.0
        date_yesterday = Date.yesterday.strftime('%Y%m%d')
        
        # shares added by donation
        shares_donated_yesterday = Donation.where("date_format(created_at, '%Y%m%d') = ?", date_yesterday).sum(:shares_added)

        # shares removed by grant
        shares_granted_yesterday = CharityGrant.where("status = ?", "sent").where("date_format(created_at, '%Y%m%d') = ?", date_yesterday).sum(:shares_subtracted)

        donors_shares_total_beginning = Share.order("created_At DESC").last.share_total_end.to_f rescue 0.0

        share_total_end = (BigDecimal("#{donors_shares_total_beginning}") + BigDecimal("#{shares_donated_yesterday}") - BigDecimal("#{shares_granted_yesterday}")).round(SHARE_PRECISION)

        # get donation share price
        # givbalance / total_donor_shares_all_time
        preliminary_share_price = (BigDecimal("#{givbalance}") / share_total_end).to_f

        preliminary_share_price = 100000.0 unless preliminary_share_price.finite?
        if preliminary_share_price.to_f.nan?
          preliminary_share_price = 100000.0
        end

        donation_share_price = (preliminary_share_price * 10).ceil / 10.0
        grant_share_price = (preliminary_share_price * 10).floor / 10.0

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

      def grantshare

        # stripe_balance = get_stripe_balance
        # etrade_balance = get_etrade_balance
        # givbalance = stripe_balance + etrade_balance
        
        givbalance = 20.0
        
        grant_price = Share.last.grant_price rescue 0.0
        giv2giv_fee = givbalance * (GIV_GRANT_AMOUNT) * (GIV_FEE_AMOUNT)
        charity_groups = CharityGroup.all

        charity_groups.each do |charity_group|

          charity_group_share_balance = charity_group.donations.sum(:shares_added) - charity_group.charity_grants.sum(:shares_subtracted)
          charity_group_grant_shares = charity_group_share_balance * GIV_GRANT_AMOUNT
          charity_grant_shares = (BigDecimal("#{charity_group_grant_shares}") / BigDecimal("#{charity_group.charities.count}")).round(SHARE_PRECISION)

          # charity_group_donors = charity_group.donors.all
          charity_group_donors = charity_group.donations
          charities = charity_group.charities

          charities.each do |charity|
            if charity.status.eql?("active")
              charity_group_donors.each do |charity_group_donor|
                grant_record = DonorGrant.new(
                                        :donor_id => charity_group_donor.donor.id,
                                        :charity_group_id => charity_group.id,
                                        :charity_id => charity.id,
                                        :date => Date.today,
                                        :shares_pending => charity_grant_shares,
                                        :status => 'pending'
                                        )
                grant_record.save
              end # end .each do |donor|
            end # charity.status = active
          end # end charities.each do |charity|
        end # end charity_groups.each do |charity_group|
      end

      def cumulative_etrade_balance(account_id)
        Etrade.update_balance(account_id)
      end

    private

      def get_stripe_balance
        begin
          stripe_balance = Stripe::Balance.retrieve
          stripe_pending = (stripe_balance["pending"][0][:amount].to_f) / 100
          stripe_available = (stripe_balance["available"][0][:amount].to_f) / 100
          total_stripe = stripe_pending + stripe_available
        rescue Stripe::CardError => e
          puts "Message is: #{err[:message]}"
        end
      end

      def get_etrade_balance
        begin
          etrade_balance = Etrade.get_net_account_value
          return etrade_balance.to_f
        rescue
          puts "Message is: API! Error"
        end
      end

    end # end self
  end
end
