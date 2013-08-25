require 'dwolla'

# Pull in configuration from yaml files

require 'yaml'


# load dwolla_secret.api_key, dwolla_secret.api_secret
dwolla_secret = YAML::load( File.open( './dwolla.yml' ) )

# Set in Dwolla object
Dwolla::api_key = dwolla_secret.api_key
Dwolla::api_secret = dwolla_secret.api_secret



class g2gDwolla

redirect_uri = 'https://www.giv2giv.org/api/oauth_return'


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
  account_info = Dwolla::Users.get #get user's data like Id, Name, Image, City, State, Latitude, Longitude - I *think* all these are possible
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
    transaction_id = Dwolla::Request.create({
    :Id => account_info['Id'],
    :amount => amount
    })
    #We need to store this transaction_id somewhere because Dwolla will callback with it
  rescue
    puts "request didn't work - account_info is scoped incorrectly?"
  end

end


end #end of class g2gDwolla
