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
  gem "debugger"
  gem "factory_girl_rails"
  gem "pry"
  gem "pry-nav"
end

gem 'rails', '3.2.13'
gem "oauth", "~> 0.4.7"
gem "mysql2"

# CORS support
gem 'rack-cors', :require => 'rack/cors'

# Scheduler
gem 'rufus-scheduler'

# Gems used to interact with payment processors
gem 'dwolla-ruby'
gem 'stripe'
gem 'httparty'

# Gems used for the charity import
gem 'nokogiri', :require => false
gem 'typhoeus', :require => false
gem 'spreadsheet'

# A little pagination
gem 'will_paginate', '~> 3.0'

# Stripe events hooks
gem 'stripe_event', :git => 'git://github.com/integrallis/stripe_event.git'