class Api::BalancesController < Api::BaseController
  before_filter :require_authentication
  include DwollaHelper

  def show_grants
    date_today = Date.today.strftime('%Y-%m-%d')
    grants = Grant.where("date = '#{date_today}'")
    
    respond_to do |format|
      format.json { render json: grants }
    end
  end

  def approve_charity
    if params.has_key?(:id)
      grant = Grant.find(params[:id])
      if grant.blank?
        render json: {:error => "Grant is not available"}.to_json
      else
        email = grant.charity.email
        notes = "Congratulations"
        # amount to send dwolla
        amount = Grant.where("charity_group_id = #{grant.charity_group_id}").sum(:shares_subtracted)        
        # send money to dwolla
        transaction_id = make_donation(email, notes, amount=nil)
        if !transaction_id.blank?
          dump_grant_sent = SentGrant.new(
                                          :date => Date.today,
                                          :charity_id => grant.charity_id,
                                          :dwolla_transaction_id => transaction_id,
                                          :amount => amount,
                                          :fee => grant.giv2giv_total_grant_fee
                                         )
          # if dwolla send, update balance and fee to charity
          if dump_grant_sent.save
            charity_update = Charity.find(grant.charity_id)
            # round up charity balance
            charity_balance = (SentGrant.where("charity_id = '#{grant.charity_id}'").sum(:amount)) * 10).ceil / 10.0
            charity_balance = (charity_balance * 10).ceil / 10.0
            update_charity_fee_balance = charity_update.update_attributes(
                                                     :fee => grant.giv2giv_total_grant_fee,
                                                     :balance => charity_balance
                                                    )
            render json: {:error => "Transfer success!"}.to_json
          else
            render json: {:error => "Error creating grant sent!"}.to_json
          end
        else
          render json: {:error => "Error creating grant sent!"}.to_json
        end # end transaction
      end # end grant blank
    else
      render json: {:error => "Required grant id"}.to_json
    end
  end

end