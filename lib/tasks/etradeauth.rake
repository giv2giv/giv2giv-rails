namespace :etradeauth do
  # bundle exec rake etradeauth:start
  task :start => :environment do
    Etrade.authenticate
  end

end