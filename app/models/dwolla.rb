require 'dwolla'

# Pull in configuration from yaml files

require 'yaml'


# Set in Dwolla object
Dwolla::api_key = App.dwolla.api_key
Dwolla::api_secret = App.dwolla.api_secret



class Company_Dwolla

Dwolla::token = App.dwolla.company_token

def self.get_company_balance
  begin
    Dwolla::Balance.get
  rescue Dwolla::APIError => error
    puts "Company_Dwolla Dwolla::Balance.get didn't work"
  end
end


end # end of Company_Dwolla class



class Donor_Dwolla


redirect_uri = 'https://www.giv2giv.org/api/oauth_return' # This is where we want dwolla to send folks after authorizing g2g at dwolla.com


def self.get_auth_url
  # To begin the OAuth process, send the user off to authUrl
  authUrl = Dwolla::OAuth.get_auth_url(redirect_uri)
  return authUrl

  # We still need a route for the oauth return

  # STEP 2:
  #   Exchange the temporary code given
  #   to us in the querystring, for
  #   a never-expiring OAuth access token like this sinatra route example
  #get '/oauth_return' do
    #code = params['code']
    #token = Dwolla::OAuth.get_token(code, redirect_uri)
    #"Your never-expiring OAuth access token is: <b>#{token}</b>"
  #end

end

def self.set_token(token=nil)
  Dwolla::token = token
end

def self.get_donor_balance

  begin
    Dwolla::Balance.get
  rescue Dwolla::APIError => error
    puts "Invalid token - make sure you set_token(token) first"
  end

end


def self.make_donation(amount=nil)

  begin
    # This is fantastically undocumented - arguments are: sourceId, amount ?

    account_info = Dwolla::Users.get #get user's data like Id, Name, Image, City, State, Latitude, Longitude - I *think* all these are possible

    transaction_id = Dwolla::Request.create({
      :sourceId => account_info['Id'],
      :amount => amount
    })
    #We need to store this transaction_id somewhere because Dwolla will callback with it
    #webhooks are specified via the dwolla.com/applications site
  rescue
    puts "request didn't work - account_info is scoped incorrectly?"
  end

end 

end # End of Donor_Dwolla class


