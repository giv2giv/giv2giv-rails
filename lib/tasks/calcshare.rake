namespace :calcshare do
  # bundle exec rake calcshare:startcalculation
  desc 'Calculate Share Price'
  task :startcalculation => :environment do
    # make this smarter and run this every minute (or 5 minutes)
    # check to see if we have successfully calculated priceshare for today
    # if we have, just return
    # if not, keep trying (and log!!!!)
    CalculationShare::Calculation.priceshare
  end

  # bundle exec rake calcshare:startgrantcalculation
  desc 'Calculate Grants'
  task :startgrantcalculation => :environment do
    CalculationShare::Calculation.grantshare
  end

end
