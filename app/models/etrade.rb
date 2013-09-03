require 'rubygems'
require 'oauth'
require 'net/http'
require 'httparty'
require 'nokogiri'
require 'yaml'
#TODO: revisit gems to check for dependencies. I just open up a pandora's box of security flaws.

class Etrade < ActiveRecord::Base
  validates :balance, :presence => true

  def self.get_auth_url
  #TODO: MAKE THIS WORK
    # To begin the OAuth process, send the user off to authUrl

    base_uri 'https://etws.etrade.com/'
    #HTTParty should handle this for all subsequent requests,
    #but if we don't want to use it we can just append to api calls
    format :xml

    # Set in app.yml

    consumer_key = App.etrade.oauth_consumer_key
    access_token = App.etrade.consumer_secret

    request_url = 'https://etws.etrade.com/oauth/request_token'
    authUrl = ETrade::OAuth.get_auth_url(request_url)
    return authUrl
    # We still need a route for the oauth return

    # STEP 2:
    #   Exchange the temporary code given
    #   to us in the querystring, for
    #   a never-expiring OAuth access token like this sinatra route example
    #get '/oauth_return' do
      #code = params['code']
      #token = Etrade::OAuth.get_token(code, redirect_uri)
      #"Your never-expiring OAuth access token is: <b>#{token}</b>"
    #end
  end

  def self.authorize(oauth_consumer_key=consumer_key, oauth_token=access_token)
    get("https://us.etrade.com/e/etws/authorize?key=#{oauth_consumer_key}&token=#{oauth_token}")
  end

  #Accounts API
  def self.get_accounts
    #If we have multiple accounts y'all gotta let me know
    doc = Nokogiri::XML(get("/accounts/rest/accountlist"))
  end

  def self.get_net_account_value
    doc = ETrade.get_accounts
    return doc.xpath("//AccountListResponse//Account//netAccountValue").inner_text
  end

  def self.get_account_id
    doc = ETrade.get_accounts
    return doc.xpath("//AccountListResponse//Account//accountId").inner_text.to_i
  end

  def self.get_detailed_account_balance
    account_id = ETrade.get_account_id
    return Nokogiri::XML(get("/accounts/rest/accountbalance/#{account_id}"))
  end

  def self.get_cash_available_for_withdrawal
    doc = self.get_detailed_account_balance
    return doc.xpath("//AccountBalanceResponse//accountBalance//cashAvailableForWithdrawal").inner_text.to_f
  end

  def self.get_net_cash
    doc = self.get_detailed_account_balance
    return doc.xpath("//AccountBalanceResponse//accountBalance//netCash").inner_text.to_f
  end

  #Begin transactions
  def self.get_transaction_history
  #last 30 days
    account_id = ETrade.get_account_id
    return Nokogiri::XML(get("/accounts/rest/#{account_id.to_s}/transactions"))
  end

  #TODO: testing - the etrade doc is not specific enough on selecting from all groups at once
  def self.get_fees
    account_id = ETrade.get_account_id
    return Nokogiri::XML(get("/accounts/rest/{account_id}/transactions/WITHDRAWALS/fee"))
  end

  def self.get_cumulative_fee_total
    doc = ETrade.get_fees
    total = 0.00
    doc.xpath("//transactions//transaction//amount").each do |fee|
      total += fee.inner_text.to_f
    end
  end

  def self.update_balance
    balance = self.get_net_account_value
    fees = self.get_cumulative_fee_total
    Etrade.create({ :balance => balance, :fees => fees, :date => Time.now.to_datetime })
  end
end




