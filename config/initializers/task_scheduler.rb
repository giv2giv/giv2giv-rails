require 'rubygems'
require 'rufus/scheduler'  

class SchedulerPrice
  attr_reader :count

  def initialize
    @count = 0
  end

  def call(job)
    @count += 1
    if @count < 10
      begin
        puts ". #{self.class} called at #{Time.now} (#{@count})"
        ret = system 'bundle exec rake calcshare:startcalculation'
        if ret == false
          puts "Task failed, try again in 5 minutes"
          job.scheduler.in '5m', self
        else
          puts "Finished running task at #{DateTime.now}"
        end
      rescue Exception => e
        puts "Request failed - recheduling: #{e}"
        job.scheduler.in '5m'
      end
    else
      ErrorJobMailer.error_priceshare(App.giv["email_support"]).deliver
      puts "Email notification has been sent"
    end # end count
  end
end # end class

class GrantPrice
  attr_reader :count_grant

  def initialize
    @count_grant = 0
  end

  def call(job)
    @count_grant += 1
    if @count_grant < 10
      begin
        puts ". #{self.class} called at #{Time.now} (#{@count_grant})"
        ret = system 'bundle exec rake calcshare:startgrantcalculation'
        if ret == false
          puts "Task failed, try again in 5 minutes"
          job.scheduler.in '5m', self
        else
          puts "Finished running task at #{DateTime.now}"
        end
      rescue Exception => e
        puts "Request failed - recheduling: #{e}"
        job.scheduler.in '5m'
      end
    else
      ErrorJobMailer.error_priceshare(App.giv["email_support"]).deliver
      puts "Email notification has been sent"
    end # end count_grant
  end
end # end class

class GrantIgnore
  attr_reader :count_ignore

  def initialize
    @count_ignore = 0
  end

  def call(job)
    @count_ignore += 1
    if @count_ignore < 10
      begin
        puts ". #{self.class} called at #{Time.now} (#{@count_ignore})"
        ret = system 'bundle exec rake calcshare:charity_ignores_grant'
        if ret == false
          puts "Task failed, try again in 5 minutes"
          job.scheduler.in '5m', self
        else
          puts "Finished running task at #{DateTime.now}"
        end
      rescue Exception => e
        puts "Request failed - recheduling: #{e}"
        job.scheduler.in '5m'
      end
    else
      ErrorJobMailer.error_priceshare(App.giv["email_support"]).deliver
      puts "Email notification has been sent"
    end # end count_ignore
  end
end # end class

scheduler = Rufus::Scheduler.new
scheduler.cron '1 0 * * *', SchedulerPrice.new, :blocking => true
scheduler.every '90d', GrantPrice.new, :blocking => true
scheduler.every '60d', GrantIgnore.new, :blocking => true