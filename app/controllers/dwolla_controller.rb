class DwollaController < Api::ApplicationController
  require 'json'
  include DwollaHelper

  def receive_hook
    begin
      signature = request.headers["HTTP_X_DWOLLA_SIGNATURE"]
      body = JSON.parse request.body.read
      # Verify signature before check transaction
      # Dwolla::OffsiteGateway.verify_webhook_signature(signature, body.to_json)

      if body.has_key?("Type") and body["Type"].eql?("Transaction")
        
        if body["Transaction"]["Status"].eql?("processed")
          charity_grant = CharityGrant.find(body["Transaction"]["Id"])
          charity_grant.update_attributes(:status => "collected")
        end

      end
      head :ok
    rescue Exception => e
      puts e.message
      head :unauthorized
    end
  end

end