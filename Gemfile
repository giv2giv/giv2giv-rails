source 'https://rubygems.org'
source 'https://code.stripe.com'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'uglifier', '>= 1.0.3'
end

group :development, :test do
  gem "rspec-rails"
  gem "capybara"
  gem "thin"
  gem "debugger"
  gem "factory_girl_rails"
  gem "pry"
  gem "pry-nav"
  gem "awesome_print"

end

gem 'rails', '3.2.17'
gem "oauth", "~> 0.4.7" # for eTrade API
gem "mysql2"

gem 'mailchimp-api'
gem 'mandrill-api'

gem "omniauth"
gem "omniauth-facebook"
gem "omniauth-dwolla"
gem "omniauth-google-oauth2", "~> 0.2.1"
gem "twitter"

# CORS support
gem 'rack-cors', :require => 'rack/cors'

# Scheduler
gem 'rufus-scheduler'

# Gems used to interact with payment processors
gem 'dwolla-ruby'
#gem 'ice_cube' # recurring billing
gem 'stripe'

gem 'httparty'

# Gems used for the charity import
gem 'nokogiri', :require => false
gem 'typhoeus', :require => false
gem 'spreadsheet'

# pagination
gem 'kaminari'

# friendly-id for nice SEO endowment URLs
gem "friendly_id", "~> 4.0.10"

# Stripe events hooks
gem 'stripe_event', :git => 'git://github.com/integrallis/stripe_event.git'
