class ErrorJobMailer < ActionMailer::Base

  require 'mandrill'
  ENV["MANDRILL_APIKEY"] = App.mailer["password"]

  def error_compute_share_price(email)
    m = Mandrill::API.new
    message = {  
     :subject=> "[ Giv2Giv ] Error Calculation error in compute_share_price", 
     :from_name=> "giv2giv.org",  
     :text=>"Calculation error",
     :to=>[  
       {  
         :email=> email
       }  
     ],  
     :html=>"<h3>Calculation error in compute_share_price</h3><br /><hr />Date : #{DateTime.now}",
     :from_email=>App.giv['email_contact']
    }  
    sending = m.messages.send message
  end

  def error_grant_step_1(email)
    m = Mandrill::API.new
    message = {  
     :subject=> "[ Giv2Giv ] Calculation error in grant_step_1", 
     :from_name=> "giv2giv.org",  
     :text=>"grant_step_1 error",
     :to=>[  
       {  
         :email=> email
       }  
     ],  
     :html=>"<h3>Calculation error in grant_step_1</h3><br /><hr />Date : #{DateTime.now}",
     :from_email=>App.giv['email_contact']
    }  
    sending = m.messages.send message
  end

  def error_send_stripe_funds(email)
    m = Mandrill::API.new
    message = {  
     :subject=> "[ Giv2Giv ] Error in sending funds from stripe to etrade", 
     :from_name=> "giv2giv.org",  
     :text=>"stripe-to-etrade transfer error",
     :to=>[  
       {  
         :email=> email
       }  
     ],  
     :html=>"<h3>Error in sending funds from stripe to etrade</h3><br /><hr />Date : #{DateTime.now}",
     :from_email=>App.giv['email_contact']
    }  
    sending = m.messages.send message
  end

end
