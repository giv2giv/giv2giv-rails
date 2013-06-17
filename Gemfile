source 'https://rubygems.org'

gem 'rails', '3.2.13'
gem 'jruby-openssl'
gem 'bcrypt-ruby'


# Gems used to interact with payment processors
gem 'dwolla-ruby'

# Gems used for the charity import
gem 'nokogiri', :require => false
gem 'typhoeus', :require => false
gem 'jruby-poi', :require => false


gem "neo4j", ">= 2.2.3"#, :path => 'vendor/gems/neo4j'
#gem "neo4j-core", :path => 'vendor/gems/neo4j-core'
gem 'neo4j-community', '1.9.M03'# :path => 'vendor/gems/neo4j-community' #'1.9.M03' # FIXME - Why use milestone release?
gem 'neo4j-advanced', '1.9.M03'#:path => 'vendor/gems/neo4j-advanced' #'1.9.M03' # FIXME - Why use milestone release?
gem 'neo4j-enterprise', '1.9.M03'#:path => 'vendor/gems/neo4j-enterprise' #'1.9.M03' # FIXME - Why use milestone release?


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyrhino'

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

group :development, :test do
  gem "rspec-rails"
#  gem "ruby-debug"
end
