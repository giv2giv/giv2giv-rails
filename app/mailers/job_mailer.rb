class JobMailer < ActionMailer::Base
  
  require 'mandrill'
  ENV["MANDRILL_APIKEY"] = App.mailer["password"]

  def success_compute(email)
    m = Mandrill::API.new
    message = {  
     :subject=> "[ giv2giv.org ] Success #{action}",  
     :from_name=> "giv2giv.org",  
     :text=>"Share price calculation successful",
     :to=>[  
       {  
         :email=> email
       }  
     ],  
     :html=>"<h3>Share price calculation success in #{action}</h3><br /><hr />Date : #{DateTime.now}",
     :from_email=>App.giv['email_support']
    }  
    sending = m.messages.send message
  end

  def send_stripe_funds(email)
    m = Mandrill::API.new
    message = {  
     :subject=> "[ giv2giv.org ] Stripe->ETrade transfer success", 
     :from_name=> "giv2giv.org",  
     :text=>"Funds sent from stripe to etrade",
     :to=>[  
       {  
         :email=> email
       }  
     ],  
     :html=>"<h3>Funds sent from stripe to etrade</h3><br /><hr />Date : #{DateTime.now}",
     :from_email=>App.giv['email_support']
    }  
    sending = m.messages.send message
  end

end
