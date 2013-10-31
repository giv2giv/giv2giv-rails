namespace :calcshare do
  # bundle exec rake calcshare:compute_share_price
  desc 'Calculate Share Price'
  task :compute_share_price => :environment do
    CalculationShare::Calculation.compute_share_price
  end

  # bundle exec rake calcshare:startgrantcalculation
  desc 'Calculate Grants'
  task :startgrantcalculation => :environment do
    CalculationShare::Calculation.grant_step_1
  end

end
