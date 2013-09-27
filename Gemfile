source 'https://rubygems.org'

gem 'rails', '3.2.13'
#gem 'jruby-openssl'
gem 'bcrypt-ruby'
gem "oauth", "~> 0.4.7"
gem "mysql2"

# Gems used to interact with payment processors
gem 'dwolla-ruby'
gem 'stripe', :git => 'https://github.com/stripe/stripe-ruby'
gem 'httparty'

# Gems used for the charity import
gem 'nokogiri', :require => false
gem 'typhoeus', :require => false
gem 'spreadsheet'

# A little pagination
gem 'will_paginate', '~> 3.0'

#gem "neo4j", ">= 2.3.0"
#gem 'neo4j-community', '1.9'
#gem 'neo4j-advanced', '1.9'
#gem 'neo4j-enterprise', '1.9'
#gem 'neo4j-will_paginate'

# Stripe events
gem 'stripe_event'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyrhino'
  gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

group :development, :test do
  gem "rspec-rails"
  gem "debugger"
#  gem "ruby-debug"
end

# CORS support
gem 'rack-cors', :require => 'rack/cors'