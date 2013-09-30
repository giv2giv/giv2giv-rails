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
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET, {:site => REQUEST_SITE, :http_method => :get})
    access_token = OAuth::Token.new(token, secret)
    consumer.request(:get, "/accounts/sandbox/rest/accountlist", access_token)
  end

  def get_net_account_value(get_accounts)
    xml = Nokogiri::XML(get_accounts)
    return xml.xpath("//AccountListResponse//Account//netAccountValue").inner_text.to_f
  end

  def get_account_id(token, secret)
    get_accounts = get_accounts(token, secret)
    xml = Nokogiri::XML(get_accounts)
    account_id = xml.xpath("//AccountListResponse//Account//accountId").inner_text.to_i
  end

  def get_detailed_account_balance(token, secret, account_id)
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET, {:site => REQUEST_SITE, :http_method => :get})
    access_token = OAuth::Token.new(token, secret)
    consumer.request(:get, "/accounts/sandbox/rest/accountbalance/#{account_id}", access_token)
  end

  def get_cash_available_for_withdrawal
    xml = get_detailed_account_balance(token, secret, account_id)
    return xml.xpath("//AccountBalanceResponse//accountBalance//cashAvailableForWithdrawal").inner_text.to_f
  end

  def get_net_cash
    xml = get_detailed_account_balance(token, secret, account_id)
    return xml.xpath("//AccountBalanceResponse//accountBalance//netCash").inner_text.to_f
  end

  #Begin transactions
  def get_transaction_history(token, secret, account_id)
  #last 30 days
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET, {:site => REQUEST_SITE, :http_method => :get})
    access_token = OAuth::Token.new(token, secret)
    consumer.request(:get, "/accounts/rest/#{account_id.to_s}/transactions", access_token)
  end

  def get_fees(token, secret, account_id)
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET, {:site => REQUEST_SITE, :http_method => :get})
    access_token = OAuth::Token.new(token, secret)
    consumer.request(:get, "/accounts/sandbox/rest/#{account_id}/transactions/WITHDRAWALS/fee", access_token)
  end

  def get_cumulative_fee_total(token, secret, account_id)
    doc = get_fees(token, secret, account_id)
    total = 0.00
    doc.xpath("//transactions//transaction//amount").each do |fee|
      total += fee.inner_text.to_f
    end
  end

  def update_balance(token, secret, account_id)
    balance = get_net_account_value(get_accounts)
    fees = get_cumulative_fee_total(token, secret, account_id)
    Etrade.create({ :balance => balance, :fees => fees, :date => Time.now.to_datetime })
  end

end