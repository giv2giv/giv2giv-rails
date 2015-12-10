namespace :calcshare do
  # bundle exec rake calcshare:compute_share_price
  desc 'Calculate Share Price'
  task :compute_share_price => :environment do
    CalculationShare::Calculation.compute_share_price
  end
end
