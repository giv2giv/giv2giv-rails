class JobMailer < ActionMailer::Base
  
  require 'mandrill'
  ENV["MANDRILL_APIKEY"] = App.mailer["password"]

  def success_compute(email, action)
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
     :html=>"<h3>Calculation success in #{action}</h3><br /><hr />Date : #{DateTime.now}",
     :from_email=>App.giv['email_support']
    }  
    sending = m.messages.send message
  end

end
