require 'stripe'
require 'oauth'
require 'bigdecimal'
include OAuth::Helper
include EtradeHelper
include DwollaHelper

SHARE_PRECISION = App.giv["share_precision"]
GIV_GRANT_AMOUNT = App.giv["giv_grant_amount"]

module CalculationShare
  class Calculation

    class << self

      def compute_share_price
        stripe_balance = get_stripe_balance
        etrade_balance = get_etrade_balance

        givbalance = stripe_balance + etrade_balance
      
        last_share = Share.order("created_at DESC").first

        begin
          share_total_beginning = last_share.share_total_end # share total at last calculation
          last_share_created_at = last_share.created_at
        rescue
          share_total_beginning = 0
          last_share_created_at = DateTime.now
        end

        # shares added by donation
        shares_added_by_donation = Donation.where("created_at >= ?", last_share_created_at).sum(:shares_added)

        # shares removed by grant
        shares_subtracted_by_grants = CharityGrant.where("status = ?", "sent").where("created_at >= ?", last_share_created_at).sum(:shares_subtracted)

        share_total_end = (BigDecimal(share_total_beginning.to_s) + BigDecimal(shares_added_by_donation.to_s) - BigDecimal(shares_subtracted_by_grants.to_s)).round(SHARE_PRECISION)

        # get donation share price
        # givbalance / total_donor_shares_all_time
        preliminary_share_price = (BigDecimal(givbalance.to_s) / BigDecimal(share_total_end.to_s)).to_f

        preliminary_share_price = 100000.0 unless preliminary_share_price.finite?
        if preliminary_share_price.to_f.nan?
          preliminary_share_price = 100000.0
        end

        donation_share_price = preliminary_share_price.ceil2(2)
        grant_share_price = preliminary_share_price.floor2(2)


        new_record_share = Share.new(
                                     :stripe_balance => stripe_balance,
                                     :etrade_balance => etrade_balance,
                                     :share_total_beginning => share_total_beginning,
                                     :shares_added_by_donation => shares_added_by_donation,
                                     :shares_subtracted_by_grants => shares_subtracted_by_grants,
                                     :share_total_end => share_total_end,
                                     :donation_price => donation_share_price,
                                     :grant_price => grant_share_price
                                    )
        if new_record_share.save
          puts "Share Price has been updated"
          JobMailer.success_compute(App.giv["email_support"], "compute_share_price").deliver
        else
          puts "ERROR"
        end
      end

      def grant_step_1
        
        endowments = Endowment.all

        #endowment_share_balance = BigDecimal("#{endowment.donations.sum(:shares_added)}") - BigDecimal("#{endowment.donor_grants.sum(:shares_subtracted)}")
        #endowment_grant_shares = (BigDecimal("#{endowment_share_balance}") * BigDecimal("#{GIV_GRANT_AMOUNT}")).round(SHARE_PRECISION)

        endowments.each do |endowment|

          charities = endowment.charities.where("active = ?", "true")

          donated_shares = endowment.donations.group(:donor_id).sum(:shares_added)

          donated_shares.each do |donor_id, shares_donor_donated|

            shares_donor_granted = endowment.donor_grants.where("donor_id = ? AND endowment_id = ? AND status = ?", donor_id, endowment.id, "sent").sum(:shares_subtracted)

            donor_share_balance = shares_donor_donated - shares_donor_granted # is BigDecimal - BigDecimal, so precision OK

            next if donor_share_balance <= 0

            shares_per_charity = (donor_share_balance * BigDecimal("#{GIV_GRANT_AMOUNT}") / BigDecimal("#{charities.count}")).round(SHARE_PRECISION)

            charities.each do |charity|
              grant_record = DonorGrant.new(
                                        :donor_id => donor_id,
                                        :endowment_id => endowment.id,
                                        :charity_id => charity.id,
                                        :date => Date.today,
                                        :shares_subtracted => shares_per_charity,
                                        :status => 'pending'
                                        )
              grant_record.save
            end

          end # donor_shares.each
        end # endowments.each
        puts "Grant share has been updated"
        JobMailer.success_compute(App.giv["email_support"], "grantcalculation_step1").deliver
      end # def grant_step_1

      def charity_ignores_grant
        charity_grants = CharityGrant.where("status = ?", "sent")

        charity_grants.each do |charity_grant|
          modify_date = (charity_grant.created_at + 60.days).to_date  
          if Date.today > modify_date
            charity_grant.update_attributes(:status => 'uncollected')
            puts "Charity grant : #{charity_grant.transaction_id} status is uncollected"
          end
        end # end each charity_grants
      end


    private

      def get_stripe_balance
        begin
          stripe_balance = Stripe::Balance.retrieve
          stripe_pending = (stripe_balance["pending"][0][:amount].to_f) / 100
          stripe_available = (stripe_balance["available"][0][:amount].to_f) / 100
          total_stripe = stripe_pending + stripe_available
          puts "Stripe Balance : #{total_stripe}"
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

        etrade_balance = BigDecimal(etrade_balance.to_s) - 1000
        puts "Etrade Balance : #{etrade_balance}"
        return etrade_balance
        
      end

    end # end self
  end
end
