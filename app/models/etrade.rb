require 'rubygems'
require 'oauth'
require 'net/http'
require 'httparty'
require 'nokogiri'
#screen scrape or oauth? decisions, decisions.
#TODO: revisit gems to check for dependencies. I just open up a pandora's box of security flaws.

class ETrade
  include HTTParty
  base_uri 'https://etws.etrade.com/'
  format :xml

  #TODO:
  CONSUMER_TOKEN = {
    :token => \access_token.token\,
    :secret => \access_token.secret\
  }

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

  def self.method_missing(method_id, *args)
    if match = /get_products_by_([_a-zA-Z]\w*)/.match(method_id.to_s)
      attribute_names = match.captures.last.split('_and_')

      request = ""
      attribute_names.each_with_index { |name, idx| request = request + name + "=" + args[idx] + (attribute_names.length-1 == idx ? "" : "&") }

      get_products(request)
    else
      super
    end
  end

end
