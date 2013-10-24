module DwollaHelper
  require 'nokogiri'
  require 'dwolla'

  API_KEY = App.dwolla["api_key"]
  API_SECRET = App.dwolla["api_secret"]
  TOKEN = App.dwolla["company_token"]
  PIN = App.dwolla["pin_account"]
  ACC_ID = App.dwolla["account_id"] 

  Dwolla::api_key = API_KEY
  Dwolla::api_secret = API_SECRET
  Dwolla::token = TOKEN

  def get_balance
    Dwolla::Balance.get
  end

  def get_contact
    Dwolla::Contacts.get
  end

  def search_contact(name)
    Dwolla::Contacts.get({:search => name})
  end

  def contact_nearby(lat, long)
    Dwolla::Contacts.nearby({:latitude => lat, :longitude => lang})
  end

  def get_user
    Dwolla::Users.get
  end

  def get_all_transaction
    Dwolla::Transactions.get
  end

  def get_detail_transaction(transactionId)
    Dwolla::Transactions.get(transactionId)
  end

  def dwolla_send(email, notes = "", amount=nil)
    begin
      transactionId = Dwolla::Transactions.send({:destinationId => ACC_ID, :pin => PIN, :destinationType => email, :amount => amount, :notes => notes})
      return transactionId
    rescue Dwolla::APIError => error
      return nil
    end
  end

  def hook(body)
    data = body
    verify = Dwolla::OffsiteGateway.verify_webhook_signature(data['Signature'], body)
    return data
  end

  def request_cancel(request_id)
    Dwolla::Request.cancel(request_id)
  end

end