class DwollaController < ApplicationController
  require 'json'

  def receive_hook
    begin

      # pseudo response code notification from dwolla
      signature = request.headers["HTTP_X_DWOLLA_SIGNATURE"]
      body = JSON.parse request.body.read

      # Verify signature before check transaction
      Dwolla::OffsiteGateway.verify_webhook_signature(signature, body.to_json)

      if body.has_key?("Type") && body["Type"].eql?("Transaction")
        transaction_id = body["Transaction"]["Id"]
        transaction = Donation.find_by(:transaction_id => transaction_id)
        if (transaction)
          # Record donation
        end
          transaction = Transfer.find_by(:transaction_id => transaction_id)

        status_transaction = Dwolla::Transactions.get(transaction_id)
        transaction.status = status_transaction["Status"]

      end # end notification transaction status

      head :ok
    rescue Exception => e
      puts e.message
      head :unauthorized
    end
  end

end
