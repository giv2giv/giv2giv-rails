class Api::BalancesController < Api::BaseController
  before_filter :require_authentication
  include DwollaHelper
  
  GIV_FEE_AMOUNT = App.giv["giv_fee_percentage"].to_f
  GIV_GRANT_AMOUNT = App.giv["giv_grant_amount"]
  SHARE_PRECISION = App.giv["share_precision"]
  PIN_DWOLLA = App.dwolla["pin_account"]
  DWOLLA_GRANT_SOURCE_ACCOUNT = App.dwolla["dwolla_grant_source_account"]
  DWOLLA_FEE_DESTINATION_ACCOUNT = App.dwolla["dwolla_fee_destination_account"]

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

    pending_grants = charity_groups_grant = DonorGrant.where("status = ?", "pending")
    total_giv2giv_fee = 0.0
    
    pending_grants.group(:charity_id).each do |pending_grant| 

      grant_shares = DonorGrant.where("charity_id = ?", pending_grant.charity_id).sum(:shares_pending)
      # round to amount
      gross_amount = ((BigDecimal("#{grant_shares}") * BigDecimal("#{Share.last.grant_price}")).to_f * 10).ceil / 10.0
      giv2giv_fee = (gross_amount * GIV_FEE_AMOUNT * 10).ceil / 10.0
      net_amount = gross_amount - giv2giv_fee
      total_giv2giv_fee += giv2giv_fee
      # set text message to charity email
      text_note = "$#{gross_amount} is being sent to you via Dwolla. Please accept this anonymous, unrestricted grant from donors at www.giv2giv.org. Contact info@giv2giv.org with any questions. Enjoy!"

      begin
        transaction_id = Dwolla::Transactions.send({:destinationId => pending_grant.charity.email, :pin => PIN_DWOLLA, :destinationType => 'email', :amount => gross_amount, :notes => text_note, :fundsSource => DWOLLA_GRANT_SOURCE_ACCOUNT})
      rescue Dwolla::APIError => error
        render json: { :message => error.message }.to_json
        return
      end

      detail_transaction = get_detail_transaction(transaction_id)
      if gross_amount > 10
        dwolla_fee = detail_transaction["fees"]["amount"]
      else
        dwolla_fee = 0
      end

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
      giv2giv_fee_balance = ((CharityGrant.where("charity_id = ?", pending_grant.charity_id).sum(:giv2giv_fee)) * 10).ceil / 10.0
      transaction_fee_balance = ((CharityGrant.where("charity_id = ?", pending_grant.charity_id).sum(:transaction_fee)) * 10).ceil / 10.0

      charity_balance = (charity_balance * 10).ceil / 10.0
      giv2giv_fee_balance = (giv2giv_fee_balance * 10).ceil / 10.0
      transaction_fee_balance = (transaction_fee_balance * 10).ceil / 10.0

      update_charity_fee_balance = charity_update.update_attributes(
        :balance => charity_balance,
        :giv2giv_fees => giv2giv_fee_balance,
        :transaction_fees => transaction_fee_balance
      )

    end

    begin
      from_etrade_to_dwolla_transaction_id = Dwolla::FundingSources.deposit(DWOLLA_GRANT_SOURCE_ACCOUNT, {:pin => PIN_DWOLLA, :amount => total_giv2giv_fee})
    rescue Dwolla::APIError => error
      render json: { :message => error.message }.to_json
      return false
    end

    save_withdraw = GivPayment.new(
                                  :from_etrade_to_dwolla_transaction_id => from_etrade_to_dwolla_transaction_id,
                                  :from_dwolla_to_giv2giv_transaction_id => nil,
                                  :amount => total_giv2giv_fee,
                                  :status => 'from_etrade_to_dwolla'
                                  )

    if save_withdraw.save
      DonorMailer.grant_fee_transfer(App.giv["email_support"], from_etrade_to_dwolla_transaction_id, total_giv2giv_fee).deliver
    end

    charity_groups_grant.group(:charity_group_id).each do |charity_group_grant|
      share_pending = DonorGrant.where("status = ? AND charity_group_id = ?", "sent", charity_group_grant.charity_group_id).sum(:shares_pending)
      grant_amount = ((BigDecimal("#{share_pending}") * BigDecimal("#{Share.last.grant_price}")).to_f * 10).ceil / 10.0
      DonorMailer.charity_group_grant_money(charity_group_grant.donor.email, charity_group_grant.charity_group.name, charity_group_grant.donor.name, grant_amount).deliver
    end

    respond_to do |format|
      format.json { render json: {:message => "Successfully approve charity"}.to_json }
    end
  end

end
