module EtradeHelper
  require 'oauth'
  require 'nokogiri'
  include OAuth::Helper
  
  CUST_KEY = App.etrade["oauth_consumer_key"]
  CUST_SECRET = App.etrade["consumer_secret"]
  SITE = "https://etws.etrade.com"
  REQUEST_SITE = "https://etwssandbox.etrade.com"
  TOKEN = EtradeToken.last.token rescue ""
  SECRET = EtradeToken.last.secret rescue ""

  def get_accounts
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET, {:site => REQUEST_SITE, :http_method => :get})
    access_token = OAuth::Token.new(TOKEN, SECRET)
    consumer.request(:get, "/accounts/sandbox/rest/accountlist", access_token).body
  end

  def get_net_account_value
    get_accounts = self.get_accounts
    xml = Nokogiri::XML(get_accounts)
    return xml.xpath("//AccountListResponse//Account//netAccountValue").inner_text.to_f
  end

  def get_account_id
    get_accounts = self.get_accounts
    xml = Nokogiri::XML(get_accounts)
    account_id = xml.xpath("//AccountListResponse//Account//accountId").map{ |node| node.text }
  end

  def get_detailed_account_balance(account_id)
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET, {:site => REQUEST_SITE, :http_method => :get})
    access_token = OAuth::Token.new(TOKEN, SECRET)
    consumer.request(:get, "/accounts/sandbox/rest/accountbalance/#{account_id}", access_token)
  end

  def get_cash_available_for_withdrawal(account_id)
    doc = self.get_detailed_account_balance(account_id).body
    xml = Nokogiri::XML(doc)
    return xml.xpath("//AccountBalanceResponse//accountBalance//cashAvailableForWithdrawal").inner_text.to_f
  end

  def get_net_cash(account_id)
    doc = self.get_detailed_account_balance(account_id).body
    xml = Nokogiri::XML(doc)
    return xml.xpath("//AccountBalanceResponse//accountBalance//netCash").inner_text.to_f
  end

  #Begin transactions
  def get_transaction_history(account_id)
  #last 30 days
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET, {:site => REQUEST_SITE, :http_method => :get})
    access_token = OAuth::Token.new(TOKEN, SECRET)
    consumer.request(:get, "/accounts/rest/#{account_id.to_s}/transactions", access_token).body
  end

  def get_fees(account_id)
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET, {:site => REQUEST_SITE, :http_method => :get})
    access_token = OAuth::Token.new(TOKEN, SECRET)
    consumer.request(:get, "/accounts/sandbox/rest/#{account_id}/transactions/WITHDRAWALS/fee", access_token).body
  end

  def get_cumulative_fee_total(account_id)
    doc = self.get_fees(account_id)
    xml = Nokogiri::XML(doc)
    total = 0.00
    xml.xpath("//transactions//transaction//amount").each do |fee|
      total += fee.inner_text.to_f
    end
    return total
  end

  def update_balance(account_id)
    balance = self.get_net_account_value
    fees = self.get_cumulative_fee_total(account_id)
    Etrade.create({ :balance => balance, :fees => fees, :date => Time.now.to_datetime })
  end

end