namespace :sample do

  # bundle exec rake sample:transfer
  task :transfer => :environment do
	  require 'dwolla'

	  API_KEY = App.dwolla["api_key"]
	  API_SECRET = App.dwolla["api_secret"]
	  TOKEN = App.dwolla["company_token"]
	  PIN_DWOLLA = App.dwolla["pin_account"]
	  ACC_ID = App.dwolla["account_id"] 
	  DWOLLA_GRANT_SOURCE_ACCOUNT = App.dwolla["dwolla_grant_source_account"]
	  DWOLLA_FEE_DESTINATION_ACCOUNT = App.dwolla["dwolla_fee_destination_account"]

	  Dwolla::api_key = API_KEY
	  Dwolla::api_secret = API_SECRET
	  Dwolla::token = TOKEN
	   
    # from_etrade_to_dwolla_transaction_id
    Dwolla::FundingSources.deposit(DWOLLA_GRANT_SOURCE_ACCOUNT, {:pin => PIN_DWOLLA, :amount => 5})
    Dwolla::FundingSources.withdraw(DWOLLA_FEE_DESTINATION_ACCOUNT, {:amount => 5, :pin => PIN_DWOLLA})
  end

end