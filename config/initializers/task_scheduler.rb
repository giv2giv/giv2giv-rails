require 'rubygems'
require 'rufus/scheduler'  

scheduler = Rufus::Scheduler.start_new

scheduler.cron '0 0 * * *' do
  system 'bundle exec rake calcshare:startcalculation'
end