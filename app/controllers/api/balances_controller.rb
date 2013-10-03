class Api::BalancesController < Api::BaseController
  include EtradeHelper
  before_filter :require_authentication

  def new_etrade_token
    newtoken = EtradeToken.new(:token => params[:token], :secret => params[:secret])

    respond_to do |format|
      if newtoken.save
        format.json { render json: newtoken }
      else
        format.json { render json: newtoken.errors }
      end
    end

  end

  def show_shares
    charity_group_id = params[:id]
  	givshares = current_donor.givshare.group(:donation_id).all(conditions: "charity_group_id = '#{charity_group_id}'")
    shares = []
    givshares.each do |givshare|
      last_donation = Givshare.where(donation_id: givshare.donation_id).last
      shares << last_donation
    end

    respond_to do |format|
      format.json { render json: shares }
    end
  end

  def share_charity_group
    charity_group_id = params[:id]
    givshares = Givshare.group(:donation_id).all(conditions: "charity_group_id = '#{charity_group_id}'")
    shares = []
    givshares.each do |givshare|
      last_donation = Givshare.where(donation_id: givshare.donation_id).last
      shares << last_donation
    end

    shares_data = {}
    shares.each do |share|
      temp_share = {share.donation_id => {"donor_id" => share.donor_id, "donation_share_price" => share.donation_price, "donation" => Donation.find(share.donation_id).amount,  "grant" => 0, "share_total" => share.share_total, "grant" => share.donor_grant, "share_granted" => share.share_granted, "charity_group_balance" => share.charity_group_balance }}
      shares_data.merge!(temp_share)
    end

    respond_to do |format|
      format.json { render json: shares_data }
    end
  end

end