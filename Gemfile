source 'https://rubygems.org'
source 'https://code.stripe.com'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'uglifier', '>= 1.0.3'
end

group :development, :test do
  gem 'rspec-rails'
  #gem 'capybara'
  gem 'thin'
  gem 'byebug'
  gem 'factory_girl_rails'
  gem 'pry'
  gem 'pry-nav'
  gem 'awesome_print'
end

gem 'rails', '4.1.4'

gem 'oauth'
gem 'mysql2'

gem 'mailchimp-api'
gem 'mandrill-api'

# Maybe add https://github.com/renz45/mandrill_mailer

gem 'gibbon'

gem 'koala'

#Charity and Endowment geocoding
gem 'geocoder'
gem 'activejob_backport' # Backported for Rails 4.1, unnecessary if we update > Rails 4.2

#Charity logo/image support
gem 'paperclip'

#Donor network - Import email contacts from gmail, hotmail, yahoo etc
gem "omnicontacts"

#graph db to map donor / charity network
gem "neo4j"


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

# Search
gem 'searchkick'

# typhoeus optimizes libcurl for charity import and searchkick
gem 'typhoeus', :require => false

# pagination
gem 'kaminari'

# friendly-id for nice SEO endowment URLs
gem 'friendly_id'

# Stripe events hooks
gem 'stripe_event', :git => 'git://github.com/integrallis/stripe_event.git'
