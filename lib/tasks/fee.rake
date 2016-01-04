namespace :fee do

  # bundle exec rake fee:calculate_fee
  desc 'Calculate Fee'
  task :calculate_fee => :environment do
    Fee.calculate_fee
  end

  # bundle exec rake fee:charge_fee
  desc 'Charge Fee'
  task :charge_fee => :environment do
    Fee.charge_fee
  end

end