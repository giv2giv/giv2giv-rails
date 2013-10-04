require 'rubygems'
require 'rufus/scheduler'  

scheduler = Rufus::Scheduler.start_new

scheduler.cron '0 0 * * *' do
  system 'bundle exec rake calcshare:startcalculation'
end

scheduler.every '30d' do
  system 'bundle exec rake calcshare:startgrantcalculation'
end