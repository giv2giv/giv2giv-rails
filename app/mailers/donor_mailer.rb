class DonorMailer < ActionMailer::Base

  require 'mandrill'
  ENV["MANDRILL_APIKEY"] = App.mailer["password"]
  @mandrill = Mandrill::API.new

  def charge_success(donor, donation_amount)
    message = {  
     :subject=> "[ giv2giv.org ] Thank you for your donation",  
     :from_name=> "giv2giv.org",  
     :text=>"Donation Successful! Thank you for your donation of #{donation_amount} to giv2giv.org. Want to see the breakdown by endowment or charity? Visit giv2giv.org",
     :to=>[  
       {  
         :email=> donor.email,
         :name=> donor.name  
       }  
     ],  
     :html=>"<h3>Donation Received!</h3><br /><hr />Thank you for your donation of #{donation_amount} to giv2giv.org. Want to see the breakdown by endowment or charity? Visit giv2giv.org<br><br>",
     :from_email=>"hello@giv2giv.org"  
    }  
    sending = @mandrill.messages.send message
  end

  def create_donor(email, donor_name)
    message = {  
     :subject=> "[ giv2giv.org ] Account created",  
     :from_name=> "giv2giv.org", 
     :text=>"Hello Kevin. #{donor_name} at #{email} just created an account at giv2giv.org",
     :to=>[ 
       {
         :email=>'kevin@giv2giv.org',
         :name=> 'Kevin Pujanauski'
       } 
     ],  
     :html=>"Hello Kevin. #{donor_name} at #{email} just created an account at giv2giv.org",
     :from_email=>"hello@giv2giv.org"  
    }  
    sending = @mandrill.messages.send message
  end


  def endowment_grant_money(email, donor_name, grant_amount)
    message = {  
     :subject=> "[ giv2giv.org ] Grant sent",  
     :from_name=> "giv2giv.org",  
     :text=>"Hello #{donor_name}. We just granted $#{grant_amount} out to charities on behalf of you and other donors at giv2giv. Want to see the breakdown by endowment or charity? Visit giv2giv.org",
     :to=>[  
       {  
         :email=> email,
         :name=> donor_name  
       }  
     ],  
     :html=>"Hello #{donor_name}. We just granted $#{grant_amount} out to charities on behalf of you and other donors at giv2giv. Want to see the breakdown by endowment or charity? Visit giv2giv.org",
     :from_email=>"hello@giv2giv.org"  
    }  
    sending = @mandrill.messages.send message
  end

  def forgot_password(donor)

    message = {  
     :subject=> "[ giv2giv.org ] Confirm your new password request",
     :from_name=> "giv2giv.org",  
     :text=>"Hello #{donor.name}. We received a request to change your password. If you did not request a password reset, ignored this email.  If you do wish to reset your password, click here to confirm: https://api.giv2giv.org/api/donors/reset_password.json?reset_token=#{donor.password_reset_token}",
     :to=>[  
       {  
         :email=> donor.email,
         :name=> donor.name  
       }  
     ],  
     :html=>"Hello #{donor.name}. We received a request to change your password. If you did not request a password reset, ignored this email. <br /><br /> If you do wish to reset your password, click here to confirm: https://api.giv2giv.org/api/donors/reset_password.json?reset_token=#{donor.password_reset_token}",
     :from_email=>"hello@giv2giv.org"  
    }  
    sending = @mandrill.messages.send message
  end

  def reset_password(email, new_password)

    message = {  
     :subject=> "[ giv2giv.org ] Your new giv2giv.org password",
     :from_name=> "giv2giv.org",  
     :text=>"Hello #{donor.name}. We've changed your password to #{new_password}   Please log in at giv2giv.org to change this to something easy to remember, but hard to guess.",
     :to=>[  
       {  
         :email=> email
       }  
     ],  
     :html=>"Hello #{donor.name}. We've changed your password to #{new_password} <br />  Please log in at giv2giv.org to change this to something easy to remember, but hard to guess.",
     :from_email=>"hello@giv2giv.org"  
    }  
    sending = @mandrill.messages.send message
  end

end
