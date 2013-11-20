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
    donor_grants = DonorGrant.where("status = ?",'pending')

    show_grants = donor_grants.group(:charity_id).map do |charity|
      {
        'charity_id' => charity.charity_id,
        'charity_email' => charity.charity.email,
        'grant_amount' => (BigDecimal("#{DonorGrant.where("charity_id = ?", charity.charity_id).sum(:shares_subtracted)}") * BigDecimal("#{Share.last.grant_price}")).round(SHARE_PRECISION)
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

    last_grant_price = Share.last_grant_price

    total_grant_shares = DonorGrant.where("status = ?", "pending").sum(:shares_subtracted)
    total_grant_amount = ((BigDecimal("#{total_grant_shares}") * BigDecimal("#{last_grant_price}")).to_f * 10).ceil / 10.0
    total_giv2giv_fee = (total_grant_amount * 10).ceil / 10.0
    results = []


# TODO delayed_job
    donor_grant_shares_by_donor = DonorGrant.select("donor_id as id").where("status = ?", "pending").distinct
    donor_grant_shares_by_donor.each do |donor_grant_share|
      donor = Donor.find(donor_grant_share.id)
      DonorMailer.endowment_grant_money(donor.email, donor.name, total_grant_amount).deliver
    end



    donor_grant_shares_by_charity = DonorGrant.select("charity_id as charity_id, sum(shares_subtracted) as shares_subtracted").where("status = ?", "pending").group("charity_id")
    donor_grant_shares_by_charity.each do |donor_grant_share|

      charity = Charity.find(donor_grant_share.id)

      gross_amount = ((BigDecimal("#{donor_grant_share.shares_subtracted}") * BigDecimal("#{last_grant_price}")).to_f * 10).ceil / 10.0
      giv2giv_fee = (gross_amount * GIV_FEE_AMOUNT * 10).ceil / 10.0
      net_amount = gross_amount - giv2giv_fee

      # set text message to charity email
      text_note = "$#{net_amount} is being sent to you via Dwolla. Please accept this anonymous, unrestricted grant from donors at www.giv2giv.org. Contact info@giv2giv.org with any questions. Do good. Be well."

      begin
        transaction_id = Dwolla::Transactions.send({:destinationId => charity.email, :pin => PIN_DWOLLA, :destinationType => 'email', :amount => net_amount, :notes => text_note, :fundsSource => DWOLLA_GRANT_SOURCE_ACCOUNT})

        if net_amount > 10
          detail_transaction = get_detail_transaction(transaction_id)
          dwolla_fee = detail_transaction["fees"]["amount"]
          net_amount = net_amount - dwolla_fee;
        else
          dwolla_fee = 0
        end

        sent_grant = CharityGrant.new(:charity_id => charity.id,
                         :transaction_id => transaction_id,
                         :gross_amount => gross_amount,
                         :giv2giv_fee => giv2giv_fee,
                         :transaction_fee => dwolla_fee,
                         :net_amount => net_amount,
                         :shares_subtracted => donor_grant_share.shares_subtracted,
                         :status => 'sent'
                         )
        sent_grant.save

        results << sent_grant

        update_grants = DonorGrants.where("status = ?", "pending").where("charity_id = ?", charity.id)

        update_grants.each do |grant|

             percent_of_grant = BigDecimal("#{grant.shares_subtracted}") / BigDecimal("#{donor_grant_share.shares_subtracted}")

             grant.update_attributes(:transaction_id => transaction_id,
                       :gross_amount => BigDecimal("#{gross_amount}") * percent_of_grant,
                       :giv2giv_fee => BigDecimal("#{giv2giv_fee}") * percent_of_grant,
                       :transaction_fee => BigDecimal("#{dwolla_fee}") * percent_of_grant,
                       :net_amount => BigDecimal("#{net_amount}") * percent_of_grant,
                       :status => 'sent'
                       )
        end

      rescue Dwolla::APIError => error
        render json: { :message => error.message }.to_json
        return false
      end

    end # donor_grant_shares_by_charity.each


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



    respond_to do |format|
      format.json { render json: {:message => "Successfully approved grants", :results => results, :fee => save_withdraw }.to_json }
    end
  end

end
