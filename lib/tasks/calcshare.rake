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

# bundle exec rake calcshare:approve_pending_grants
  desc 'Approve Pending Grants'
  task :approve_pending_grants => :environment do
    CalculationShare::Calculation.approve_pending_grants
  end

# bundle exec rake calcshare:update_grant_status
  desc 'Update Grant Status'
  task :update_grant_status => :environment do
    CalculationShare::Calculation.update_grant_status
  end

end
