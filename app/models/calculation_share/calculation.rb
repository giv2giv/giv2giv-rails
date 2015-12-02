require 'stripe'
require 'oauth'
require 'bigdecimal'
include OAuth::Helper
include EtradeHelper

SHARE_PRECISION = App.giv["share_precision"]

module CalculationShare
  class Calculation

    class << self

      def compute_share_price

        stripe_balance = get_stripe_balance
        etrade_balance = get_etrade_balance
        dwolla_balance = get_dwolla_balance
        transit_balance = get_transit_balance

        current_balance = stripe_balance + etrade_balance + dwolla_balance + transit_balance
      
        last_share = Share.order("created_at DESC").first

        begin
          share_total_beginning = last_share.share_total_end # share total at last calculation
          last_share_created_at = last_share.created_at
        rescue
          share_total_beginning = 0
          last_share_created_at = DateTime.new(2001,2,3) 
        end

        # shares added by donation
        shares_added_by_donation = Donation.where("created_at >= ?", last_share_created_at).sum(:shares_added)

        # shares removed by grant
        shares_subtracted_by_grants = Grant.where("status = ? AND created_at >= ?", 'accepted', last_share_created_at).sum(:shares_subtracted)

        share_total_end = (BigDecimal(share_total_beginning.to_s) + BigDecimal(shares_added_by_donation.to_s) - BigDecimal(shares_subtracted_by_grants.to_s)).round(SHARE_PRECISION)

        # get donation share price
        # current_balance / shares_outstanding
        preliminary_share_price = (BigDecimal(current_balance.to_s) / BigDecimal(share_total_end.to_s)).to_f

        preliminary_share_price = 100000.0 unless preliminary_share_price.finite?
        if preliminary_share_price.to_f.nan?
          preliminary_share_price = 100000.0
        end

        donation_share_price = preliminary_share_price.ceil2(2)
        grant_share_price = preliminary_share_price.floor2(2)

        new_record_share = Share.new(
                                     :stripe_balance => stripe_balance,
                                     :etrade_balance => etrade_balance,
                                     :dwolla_balance => dwolla_balance,
                                     :transit_balance => transit_balance,
                                     :share_total_beginning => share_total_beginning,
                                     :shares_added_by_donation => shares_added_by_donation,
                                     :shares_subtracted_by_grants => shares_subtracted_by_grants,
                                     :share_total_end => share_total_end,
                                     :donation_price => donation_share_price,
                                     :grant_price => grant_share_price
                                    )
        if new_record_share.save
          puts "Share Price has been updated"
          JobMailer.success_compute(App.giv["email_contact"]).deliver
        else
          puts "ERROR"
        end
      end

      def clear_transit_funds
        #examine etrade transactions, set matching TransitFunds.clear=true
      end

     def project_amount (options = {})

      default_options = {
          :principal=>0,
          :monthly_addition=>0, 
          :years=>25, 
          :return_rate=>0.07
      }

      options = default_options.merge(options)

      principal = options[:principal]
      monthly_addition = options[:monthly_addition]
      years = options[:years]
      return_rate = options[:return_rate]

      amount_array = []
      total_donations = 0.0
      total_grants = 0.0
      total_fees = 0.0

      month = 1

      while month <= years * 12 do
        month = month + 1
        total_donations += monthly_addition
        principal += monthly_addition
        principal += principal * (return_rate / 12) 
        if month % 4 == 0
          grant_amount = principal * App.giv["quarterly_grant_percent"]
          total_grants += grant_amount
          fee_amount = principal * App.giv["quarterly_fee"]
          total_fees += fee_amount
          principal -= grant_amount
          principal -= fee_amount
        end
        if month % 12 == 0
          amount_hash = {
            "date" => Date.today + month.months,
            "total_donations" => total_donations.floor2(2),
            "total_grants" => total_grants.floor2(2),
            "total_fees" => total_fees.floor2(2),
            "balance" => principal.floor2(2)      
          }
          amount_array << amount_hash
        end

      end

      amount_array

    end


    private

      def get_current_balance
        get_stripe_balance + get_etrade_balance + get_dwolla_balance + get_transit_balance
      end

      def get_stripe_balance
        begin
          stripe_balance = Stripe::Balance.retrieve
          stripe_pending = (stripe_balance["pending"][0][:amount].to_f) / 100
          stripe_available = (stripe_balance["available"][0][:amount].to_f) / 100
          total_stripe = stripe_pending + stripe_available
          #puts "Stripe Balance : #{total_stripe}"
          return total_stripe
        rescue Stripe::CardError => e
          body = e.json_body
          err  = body[:error]
          Rails.logger.debug "Status is: #{e.http_status}"
          Rails.logger.debug "Type is: #{err[:type]}"
          Rails.logger.debug "Code is: #{err[:code]}"
          Rails.logger.debug "Param is: #{err[:param]}"
          Rails.logger.debug "Message is: #{err[:message]}"
        end
      end

      def get_etrade_balance
        # just let return error message default from api
        etrade_balance = Etrade.get_net_account_value
        raise "eTrade connection problem" if !etrade_balance

        etrade_balance = BigDecimal(etrade_balance.to_s)

      end

      def get_dwolla_balance
        return 0
        #dwolla_balance = DwollaLibs.new.get_balance
        #raise "Dwolla connection problem" if !dwolla_balance
        #BigDecimal('#{dwolla_balance}')
      end

      def get_transit_balance
        TransitFund.where("cleared IS NULL").sum(:amount)
      end

    end # end self
  end
end
