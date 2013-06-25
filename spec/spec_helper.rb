# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'fileutils'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.before(:suite) do
    delete_neo4j_database
  end

end

def delete_neo4j_database
  path = Giv2givRails::Application.config.neo4j.storage_path
  FileUtils.rm_rf(path)
end

def setup_authenticated_session(donor = default_donor)
  sess = Session.create(:donor => donor)
  request.env['HTTP_AUTHORIZATION'] = "Token token=#{sess.token}"
  sess
end

# poor mans fixtures
def default_donor
  @default_donor ||= Donor.find_by_email('asdf@ltc.com') || Donor.create(:email => 'asdf@ltc.com', :name => 'KM', :password => 'dreams')
end

def default_payment_account
  donor = default_donor
  pa = nil
  if donor.payment_accounts.length > 0
    pa = donor.payment_accounts.first
  else
    pa = donor.payment_accounts.build(:processor => 'dwolla', :token => 'Allowd')
    pa.save
  end
  pa
end

def default_charity_group
  @default_cg ||= CharityGroup.find('name: Kendal', :type => :fulltext) || create_defalt_charity_group
end

def create_defalt_charity_group
  cg = CharityGroup.new(:name => 'Kendal')
  cg.charities << default_charity_1
  cg.save
  cg
end

def default_charity_1
  @dc1 ||= Charity.find_by_ein(660779435) || Charity.create(:ein => 660779435, :name => 'Charitables')
end

def default_charity_2
  @dc1 ||= Charity.find_by_ein(943566077) || Charity.create(:ein => 943566077, :name => 'Goobers')
end
