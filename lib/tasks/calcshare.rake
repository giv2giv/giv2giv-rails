namespace :calcshare do
  # bundle exec rake calcshare:startcalculation
  desc 'Calculate Share Price'
  task :startcalculation => :environment do
    CalculationShare::Calculation.priceshare
  end
 end
