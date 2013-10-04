namespace :etradeauth do
  # bundle exec rake etradeauth:start
  task :start => :environment do

    require 'oauth'
    include OAuth::Helper

    CUST_KEY = "4d2fd4cd312c1904069f2970c89899df"
    CUST_SECRET = "57ae0f198d4b8efb4e73d95d35cfcc3f"

    consumer = OAuth::Consumer.new(CUST_KEY, CUST_SECRET, {:site => "https://etws.etrade.com", :http_method => :get})
    request_token = consumer.get_request_token()

    puts "In your browser, go to https://us.etrade.com/e/t/etws/authorize?key=#{escape(CUST_KEY)}&token=#{escape(request_token.token)}"
    puts "Once you have authorized this app, enter your pin here and press enter : "

    pin = $stdin.readline().chomp

    access_token = consumer.get_access_token(request_token,{:oauth_verifier => pin})
    newtoken = EtradeToken.new(:token => access_token.token, :secret => access_token.secret)
    if newtoken.save
        puts "Token has been updated !"
    else
        puts "Failed updating the token !"
    end
  end

  # bundle exec rake etradeauth:updatebalance account_id=account_id
  task :updatebalance => :environment do
    account_id = ENV['account_id']
    raise ArgumentError, 'Must specify account id' if account_id.nil?
    CalculationShare::Calculation.cumulative_etrade_balance(account_id)
  end

end