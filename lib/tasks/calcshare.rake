namespace :calcshare do
  # bundle exec rake calcshare:startcalculation
  desc 'Calculate Share Price'
  task :startcalculation => :environment do
    CalculationShare::Calculation.priceshare
  end

  # bundle exec rake calcshare:startgrantcalculation
  desc 'Calculate Grants'
  task :startgrantcalculation => :environment do
    CalculationShare::Calculation.grantshare
  end

end