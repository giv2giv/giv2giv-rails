namespace :grant do

  # bundle exec rake grant:startgrantcalculation
  desc 'Calculate Grants'
  task :startgrantcalculation => :environment do
    Grant.grant_step_1
  end

# bundle exec rake grant:approve_pending_grants
  desc 'Approve Pending Grants'
  task :approve_pending_grants => :environment do
    Grant.approve_pending_grants
  end

# bundle exec rake grant:update_grant_status
  desc 'Update Grant Status'
  task :update_grant_status => :environment do
    CalculationShare::Calculation.update_grant_status
  end

end
