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

  def get_detail_transaction
    Dwolla::Transactions.get
  end

  def make_donation(email, notes, amount=nil)
    begin
      transactionId = Dwolla::Transactions.send({:destinationId => ACC_ID, :pin => PIN, :destinationType => email, :amount => amount, :notes => notes})
      return "Success send money !"
    rescue Dwolla::APIError => error
      return "Failed send money !"
    end
  end

end