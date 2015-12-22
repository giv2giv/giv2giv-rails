namespace :grant do

  # bundle exec rake grant:startgrantcalculation
  desc 'Calculate Grants'
  task :startgrantcalculation => :environment do
    Grant.grant_step_1
  end

# bundle exec rake grant:approve_pending_passthru_grants
  desc 'Approve Pending Passthru Grants'
  task :approve_pending_passthru_grants => :environment do
    Grant.approve_pending_passthru_grants
  end

# bundle exec rake grant:approve_pending_endowed_grants
  desc 'Approve Pending Endowed Grants'
  task :approve_pending_endowed_grants => :environment do
    Grant.approve_pending_endowed_grants
  end

# bundle exec rake grant:update_grant_status
  desc 'Update Grant Status'
  task :update_grant_status => :environment do
    Grant.update_grant_status
  end

end
