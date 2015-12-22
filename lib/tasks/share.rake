namespace :share do
  # bundle exec rake share:compute_share_price
  desc 'Calculate Share Price'
  task :compute_share_price => :environment do
    Share.compute_share_price
  end
end
