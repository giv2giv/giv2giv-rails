module EtradeHelper
  require 'oauth'
  require 'nokogiri'
  include OAuth::Helper

  CUST_KEY = App.etrade["oauth_consumer_key"]
  CUST_SECRET = App.etrade["consumer_secret"]
  REQUEST_SITE = App.etrade["etrade_site"]
  TOKEN = EtradeToken.last.token rescue ""
  SECRET = EtradeToken.last.secret rescue ""

  def get_accounts
    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET, {:site => REQUEST_SITE, :http_method => :get})
    access_token = OAuth::Token.new(TOKEN, SECRET)
    consumer.request(:get, "/accounts/rest/accountlist", access_token).body
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
    consumer.request(:get, "/accounts/rest/accountbalance/#{account_id}", access_token)
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
    consumer.request(:get, "/accounts/rest/#{account_id}/transactions/WITHDRAWALS/fee", access_token).body
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
    new_calc = Etrade.new({ :balance => balance, :fees => fees, :date => Time.now.to_datetime })
    if new_calc.save
      new_calc
    else
      new_calc.errors
    end
  end

  def preview_order(action,symbol,quantity,transaction_id)
  #action should be BUY or SELL
  #clientOrderId is internal only it should be transaction_id
  #priceType can be changed to limit but then would require a limit price
    account_id = EtradeHelper.get_account_id
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.PlaceEquityOrder('xmlns' => 'http://order.etws.etrade.com') {
        xml.EquityOrderRequest {
          xml.accountId "#{account_id}"
          xml.limitPrice
          xml.previewId
          xml.stopPrice
          xml.allOrNone
          xml.quantity "#{quantity}"
          xml.reserveOrder
          xml.reserveQuantity
          xml.symbol "#{symbol}"
          xml.orderAction "#{action}"
          xml.priceType "MARKET"
          xml.routingDestination
          xml.marketSession "REGULAR"
          xml.orderTerm "GOOD_FOR_DAY"
          xml.clientOrderId "#{transaction_id}"
        }
      }
    end
    xml = builder.to_xml
    site = REQUEST_SITE+"/order/rest/previewequityorder"
    return preview_reponse = Net::HTTP.post_form(URI.parse(site), xml)
  end

  def order(action,symbol,quantity,transaction_id)
  #action should be BUY or SELL
  #clientOrderId is internal only it should be transaction_id
  #priceType can be changed to limit but then would require a limit price
  preview_reponse = EtradeHelper.preview_order(action,symbol,quantity,transaction_id)
  doc             = Nokogiri.XML(preview_reponse)
  account_id           = doc.at("accountId").text
  preview_id           = doc.at("previewId").text
  estimatedCommission  = doc.at("estimatedCommission").text
  estimatedTotalAmount = doc.at("estimatedTotalAmount").text
  quantity             = doc.at("quantity").text
  symbol               = doc.at("symbol").text
  action               = doc.at("orderAction").text


  builder = Nokogiri::XML::Builder.new do |xml|
    xml.PlaceEquityOrder('xmlns' => 'http://order.etws.etrade.com') {
      xml.EquityOrderRequest {
        xml.accountId "#{account_id}"
        xml.clientOrderId "#{transaction_id}"
        xml.limitPrice
        xml.previewId "#{preview_id}"
        xml.stopPrice
        xml.allOrNone
        xml.quantity "#{quantity}"
        xml.reserveOrder
        xml.reserveQuantity
        xml.symbol "#{symbol}"
        xml.orderAction "#{action}"
        xml.priceType "MARKET"
        xml.routingDestination
        xml.marketSession "REGULAR"
        xml.orderTerm "GOOD_FOR_DAY"
      }
    }
    end
    xml = builder.to_xml
    site = REQUEST_SITE+"/order/rest/previewequityorder"
    order_reponse = Net::HTTP.post_form(URI.parse(site), xml)
  end
end
