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
    site = REQUEST_SITE+"/order/sandbox/rest/previewequityorder"
    return preview_reponse = Net::HTTP.post_form(URI.parse(site), xml)
  end
  <PreviewEquityOrderResponse>
   <equityOrderResponse>
     <accountId>83405188</accountId>
     <allOrNone>false</allOrNone>
     <estimatedCommission>7.99</estimatedCommission>
     <estimatedTotalAmount>795.99</estimatedTotalAmount>
     <messageList>
       <message>
         <msgDesc>You have an existing open order for this security on the same
           side of the market. If you did not intend to place a second order
           for this security, please modify your order now.
         </msgDesc>
         <msgCode>1042</msgCode>
       </message>
     </messageList>
     <previewTime>1269428745346</previewTime>
     <previewId>449548380022</previewId>
     <quantity>4</quantity>
     <reserveOrder>false</reserveOrder>
     <reserveQuantity>0</reserveQuantity>
     <orderTerm>GOOD_FOR_DAY</orderTerm>
     <limitPrice>0</limitPrice>
     <stopPrice>197</stopPrice>
     <symbolDesc>INTERNATIONAL BUSINESS MACHS COM</symbolDesc>
     <symbol>IBM</symbol>
     <orderAction>BUY</orderAction>
     <priceType>STOP</priceType>
   </equityOrderResponse>
 </PreviewEquityOrderResponse>

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
    site = REQUEST_SITE+"/order/sandbox/rest/previewequityorder"
    order_reponse = Net::HTTP.post_form(URI.parse(site), xml)
  end
end