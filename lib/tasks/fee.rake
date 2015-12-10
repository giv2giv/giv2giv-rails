namespace :fee do

  # bundle exec rake fee:calculate_fee
  desc 'Calculate Fee'
  task :calculate_fee => :environment do
    Fee.calculate_fee
  end

  # bundle exec rake fee:approve_fee
  desc 'Approve Fee'
  task :approve_fee => :environment do
    Fee.approve_fee
  end

end