namespace :grant do

  # bundle exec rake grant:calculate_pending_endowed_grants
  desc 'Calculate Endowed Grants'
  task :calculate_pending_endowed_grants => :environment do
    Grant.calculate_pending_endowed_grants
  end

# bundle exec rake grant:list_pending_passthru_grants
  desc 'List Pending Passthru Grants'
  task :list_pending_passthru_grants => :environment do
    Grant.list_pending_passthru_grants
  end

# bundle exec rake grant:approve_pending_passthru_grants
  desc 'Approve Pending Passthru Grants'
  task :approve_pending_passthru_grants => :environment do
    Grant.approve_pending_passthru_grants
  end

# bundle exec rake grant:list_pending_endowed_grants
  desc 'List Pending Endowed Grants'
  task :list_pending_endowed_grants => :environment do
    Grant.list_pending_endowed_grants
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
