require 'rubygems'
require 'rufus/scheduler'  

class StripeTransfer

  def call(job)
    puts ". #{self.class} called at #{Time.now} (#{@count_grant})"
    ret = system 'bundle exec rake transit:send_stripe_funds'
    if ret == false
      ErrorJobMailer.error_send_stripe_funds(App.giv["email_support"]).deliver
    else
      JobMailer.success_job_scheduler(App.giv["email_support"], "startgrantcalculation_step1").deliver
      puts "Finished running task at #{DateTime.now}"
    end
  end

end # end class


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
        ret = system 'bundle exec rake calcshare:compute_share_price'
        if ret == false
          puts "Task failed, try again in 5 minutes"
          job.scheduler.in '5m', self
        else
          # if success do charity ignore grants
          #system 'bundle exec rake calcshare:charity_ignores_grant'
          #JobMailer.success_job_scheduler(App.giv["email_support"], "compute_share_price").deliver
          #puts "Finished running task at #{DateTime.now}"
        end
      rescue Exception => e
        puts "Request failed - recheduling: #{e}"
        job.scheduler.in '5m'
      end
    else
      # do charity ignore grants before send email error calculation shareprice
      #system 'bundle exec rake calcshare:charity_ignores_grant'
      
      ErrorJobMailer.error_compute_share_price(App.giv["email_support"]).deliver
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
          JobMailer.success_job_scheduler(App.giv["email_support"], "startgrantcalculation_step1").deliver
          puts "Finished running task at #{DateTime.now}"
        end
      rescue Exception => e
        puts "Request failed - recheduling: #{e}"
        job.scheduler.in '5m'
      end
    else
      ErrorJobMailer.error_compute_share_price(App.giv["email_support"]).deliver
      puts "Email notification has been sent"
    end # end count_grant
  end
end # end class

scheduler = Rufus::Scheduler.new
scheduler.every '1d', StripeTransfer.new, :blocking => true #Don't make this automatic yet
#scheduler.cron '5 0 * * *', SchedulerPrice.new, :blocking => true # midnight ET?
#scheduler.every '90d', GrantPrice.new, :blocking => true #Don't make this automatic yet
