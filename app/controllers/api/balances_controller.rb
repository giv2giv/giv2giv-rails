class Api::BalancesController < Api::BaseController
  before_filter :require_authentication
  include DwollaHelper
  
  GIV_FEE_AMOUNT = App.giv["giv_fee_percentage"].to_f
  GIV_GRANT_AMOUNT = App.giv["giv_grant_amount"]
  SHARE_PRECISION = App.giv["share_precision"]
  PIN_DWOLLA = App.dwolla["pin_account"]
  DWOLLA_GRANT_SOURCE_ACCOUNT = App.dwolla["dwolla_grant_source_account"]

  def show_grants
    pending_grants = DonorGrant.where("status = ?",'pending')

    show_grants = pending_grants.group(:charity_id).map do |charity|
      {
        'charity_id' => charity.charity_id,
        'charity_email' => charity.charity.email,
        'grant_amount' => (BigDecimal("#{DonorGrant.where("charity_id = ?", charity.charity_id).sum(:shares_pending)}") * BigDecimal("#{Share.last.grant_price}")).round(SHARE_PRECISION)
      }
    end
    respond_to do |format|
      format.json { render json: show_grants }
    end
  end

  def deny_grant
    charity_id = params[:id]
    denied_grants = DonorGrant.where("status = ? AND charity_id = ?", "pending", charity_id)
    denied_grants.each do |deny_grant|
      deny_grant.update_attributes(:status => 'denied')
    end
    
    respond_to do |format|
      format.json { render json: {:message => "Successfully denied charity"}.to_json }
    end

  end 

  def approve_donor_grants
    pending_grants = DonorGrant.where("status = ?", "pending")
    pending_grants.group(:charity_id).each do |pending_grant| 
      grant_shares = DonorGrant.where("charity_id = ?", pending_grant.charity_id).sum(:shares_pending)
      # round to amount
      gross_amount = ((BigDecimal("#{grant_shares}") * BigDecimal("#{Share.last.grant_price}")).to_f * 10).ceil / 10.0
      giv2giv_fee = (gross_amount * GIV_FEE_AMOUNT * 10).ceil / 10.0
      net_amount = gross_amount - giv2giv_fee
      total_giv2giv_fee = net_amount + giv2giv_fee
      # set text message to charity email
      text_note = ""
      transaction_id = Dwolla::Transactions.send({:destinationId => pending_grant.charity.email, :pin => PIN_DWOLLA, :destinationType => 'email', :amount => amount, :notes => text_note, :fundsSource => DWOLLA_GRANT_SOURCE_ACCOUNT})
      # need fix dwolla fee
      # dwolla_fee = dwolla_transaction.fee
      dwolla_fee = 0

      # set status = 'sent' for all DonorGrants rows for this charity_id
      pending_grant.update_attributes(:status => "sent", :transaction_id => transaction_id)
      sent_grant = CharityGrant.new(
                                    :date => Date.today,
                                    :charity_id => pending_grant.charity_id,
                                    :charity_group_id => pending_grant.charity_group_id,
                                    :donor_id => pending_grant.donor_id,
                                    :transaction_id => transaction_id,
                                    :transaction_fee => dwolla_fee,
                                    :giv2giv_fee => giv2giv_fee,
                                    :shares_subtracted => grant_shares,
                                    :gross_amount => gross_amount,
                                    :grant_amount => net_amount - dwolla_fee,
                                    :status => "sent"
                                    )
      sent_grant.save

      charity_update = Charity.find(pending_grant.charity_id)
      # round up charity balance
      charity_balance = ((CharityGrant.where("charity_id = ?", pending_grant.charity_id).sum(:grant_amount)) * 10).ceil / 10.0
      fee_balance = ((CharityGrant.where("charity_id = ?", pending_grant.charity_id).sum(:giv2giv_fee)) * 10).ceil / 10.0
      charity_balance = (charity_balance * 10).ceil / 10.0
      fee_balance = (fee_balance * 10).ceil / 10.0
      update_charity_fee_balance = charity_update.update_attributes(
        :balance => charity_balance,
        :fee => fee_balance
      )

    end
      
    respond_to do |format|
      format.json { render json: {:message => "Successfully approve charity"}.to_json }
    end
  end

end
