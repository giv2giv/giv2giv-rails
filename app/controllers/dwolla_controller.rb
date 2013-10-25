class DwollaController < Api::ApplicationController
  require 'json'
  include DwollaHelper
  
  PIN_DWOLLA = App.dwolla["pin_account"]
  DWOLLA_GRANT_SOURCE_ACCOUNT = App.dwolla["dwolla_grant_source_account"]
  DWOLLA_FEE_DESTINATION_ACCOUNT = App.dwolla["dwolla_fee_destination_account"]

  def receive_hook
    begin

      # pseudo response code notification from dwolla
      signature = request.headers["HTTP_X_DWOLLA_SIGNATURE"]
      body = JSON.parse request.body.read

      # Verify signature before check transaction
      Dwolla::OffsiteGateway.verify_webhook_signature(signature, body.to_json)

      if body.has_key?("Type") and body["Type"].eql?("Transaction")
        
        if body["Transaction"]["Status"].eql?("processed")
          # 3-5 days later , after transaction from etrade to dwolla
          check_giv_payment = GivPayment.find_by_from_etrade_to_dwolla_transaction_id(body["Transaction"]["Id"]) rescue nil

          if check_giv_payment.blank?

            # check dwolla to giv2giv transaction
            check_dwolla_to_giv2giv_transaction = GivPayment.find_by_from_dwolla_to_giv2giv_transaction_id(body["Transaction"]["Id"]) rescue nil
            if check_dwolla_to_giv2giv_transaction.blank?

              charity_grant = CharityGrant.find(body["Transaction"]["Id"])
              charity_grant.update_attributes(:status => "collected")

            else
              # if transaction complete
              dwolla_status_transaction = Dwolla::Transactions.get(body["Transaction"]["Id"])
              # set status data from response : https://developers.dwolla.com/dev/pages/statuses
              check_dwolla_to_giv2giv_transaction.update_attributes(:status => dwolla_status_transaction["Status"])
            end # end check_dwolla_to_giv2giv_transaction

          else
            
            from_dwolla_to_giv2giv_transaction_id = Dwolla::FundingSources.withdraw(DWOLLA_FEE_DESTINATION_ACCOUNT, {:pin => PIN_DWOLLA, :amount => check_giv_payment.amount})

            save_withdraw = GivPayment.new(
                        :from_etrade_to_dwolla_transaction_id => nil,
                        :from_dwolla_to_giv2giv_transaction_id => from_dwolla_to_giv2giv_transaction_id,
                        :amount => check_giv_payment.amount,
                        :status => 'from_dwolla_to_giv2giv'
                        )

            if save_withdraw.save
              DonorMailer.grant_transfer_requested(App.giv["email_support"], from_dwolla_to_giv2giv_transaction_id, check_giv_payment.from_etrade_to_dwolla_transaction_id, check_giv_payment.amount).deliver
            end

          end # check_giv_payment
        end # end status processed
      end # end notification transaction status

      head :ok
    rescue Exception => e
      puts e.message
      head :unauthorized
    end
  end

end