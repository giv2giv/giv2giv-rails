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
    if params[:grant_id].has_key?
      grant = Grant.find(params[:grant_id])
      if grant.blank?
        render json: {:error => "Grant is not available"}.to_json
      else
        email = grant.charity.email
        notes = "Congratulations"
        # amount to send dwolla
        amount = Grant.where("charity_group_id = #{grant.charity_group_id}").sum(:shares_subtracted)        
        # send money to dwolla
        transaction_id = make_donation(email, notes, amount=nil)
        if transaction_id.blank?
          dump_grant_sent = GrantSent.new(
                                          :date => Date.today,
                                          :charity_id => grant.charity_id,
                                          :dwolla_transaction_id => transaction_id,
                                          :amount => amount,
                                          :fee => grant.giv2giv_total_grant_fee
                                         )
          # if dwolla send, update balance and fee to charity
          if dump_grant_sent.save
            charity_update = Charity.find(grant.charity_id)
            update_charity_fee_balance = charity_update.update_attributes(
                                                     :fee => grant.giv2giv_total_grant_fee,
                                                     :balance => amount
                                                    )
          else
            render json: {:error => "Error creating grant sent!"}.to_json
          end

        end # end transaction
      end # end grant blank
    else
      render json: {:error => "Required grant id"}.to_json
    end
  end

end