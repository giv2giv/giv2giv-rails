require 'rubygems'
require 'oauth'
require 'net/http'
require 'httparty'
require 'nokogiri'
requite 'yaml'
#screen scrape or oauth? decisions, decisions.
#TODO: revisit gems to check for dependencies. I just open up a pandora's box of security flaws.

class ETrade
  include HTTParty
  base_uri 'https://etws.etrade.com/'
  #HTTParty should handle this for all subsequent requests,
  #but if we don't want to use it we can just append to api calls
  format :xml

  # load dwolla_secret.api_key, dwolla_secret.api_secret
  etrade_consumer = YAML::load( File.open( './etrade_consumer.yml' ) )

  # Set in Dwolla object
  ETrade::api_key = etrade_consumer.oauth_consumer_key
  ETrade::api_secret = etrade_consumer.consumer_secret

  ACCESS_TOKEN = {
    :token => \access_token.token\,
    :secret => \access_token.secret\
  }

  #For y'alls error checkings
  def self.test_connection

  end

  def self.authorize(oauth_consumer_key=CONSUMER_KEY, oauth_token=ACCESS_TOKEN)
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

  def self.get_transcation_history
    account_id = ETrade.get_account_id
    return Nokogiri::XML(get("/accounts/rest/{account_id}/transactions"))
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

end

