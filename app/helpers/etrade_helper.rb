module EtradeHelper
  require 'oauth'
  require 'nokogiri'
  include OAuth::Helper
  
  CUST_KEY = App.etrade["oauth_consumer_key"]
  CUST_SECRET = App.etrade["consumer_secret"]
  SITE = "https://etws.etrade.com"
  REQUEST_SITE = "https://etwssandbox.etrade.com"

  def get_auth
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET, {:site => SITE, :http_method => :get})
    request_token = consumer.get_request_token()
    return "https://us.etrade.com/e/t/etws/authorize?key=#{escape(CUST_KEY)}&token=#{escape(request_token.token)}"
  end

  def enter_verifier(pin)
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET, {:site => SITE, :http_method => :get})
    request_token = consumer.get_request_token()
    access_token = consumer.get_access_token(request_token,{:oauth_verifier => pin})
    result = {"token" => access_token.token, "secret" => access_token.secret}    
  end

  def get_accounts(token, secret)
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET,{:site => REQUEST_SITE, :http_method => :get})
    access_token = OAuth::Token.new(token, secret)
    consumer.request(:get, "/accounts/sandbox/rest/accountlist", access_token)
  end

  def get_account_id(token, secret)
    get_accounts = get_accounts(token, secret)
    xml = Nokogiri::XML(get_accounts)
    account_id = xml.xpath("//AccountListResponse//Account//accountId").text
  end

  def get_detailed_account_balance(token, secret, account_id)
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET,{:site => REQUEST_SITE, :http_method => :get})
    access_token = OAuth::Token.new(token, secret)
    consumer.request(:get, "/accounts/sandbox/rest/accountbalance/#{account_id}", access_token)
  end

  def get_fees(token, secret, account_id)
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET,{:site => REQUEST_SITE, :http_method => :get})
    access_token = OAuth::Token.new(token, secret)
    consumer.request(:get, "/accounts/sandbox/rest/#{account_id}/transactions/WITHDRAWALS/fee", access_token)
  end

end