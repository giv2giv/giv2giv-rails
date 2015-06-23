class DonorMailer < ActionMailer::Base

  require 'mandrill'

  ENV["MANDRILL_APIKEY"] = App.mailer["password"]
  
  def charge_success(donor, endowment, donation_amount)
    m= Mandrill::API.new 

    donor_message = {  
     :subject=> "[ giv2giv.org ] Thank you for your donation",  
     :from_name=> "giv2giv.org",  
     :text=>"Donation Successful! Thank you for your donation of $#{donation_amount} to the giv2giv.org fund <a href=https://giv2giv.org/#endowment/#{endowment.slug}>#{endowment.name}</a>. Want to see the breakdown by charity, or print a statement? Visit <a href=https://giv2giv.org/#endowment/#{endowment.slug}>giv2giv.org</a>",
     :to=>[  
       { 
         :email=> donor.email,
         :name=> donor.name  
       }  
     ],  
     :html=>"<h3>Donation Received!</h3><br /><hr />Thank you for your donation of #{donation_amount} to the giv2giv.org fund <a href=https://giv2giv.org/#endowment/#{endowment.slug}>#{endowment.name}</a>. Want to see the breakdown by charity, or print a statement? Visit <a href=https://giv2giv.org/#endowment/#{endowment.slug}>giv2giv.org</a><br><br>",
     :from_email=>"hello@giv2giv.org"  
    }

    sending = m.messages.send donor_message

    begin
      charities = endowment.charities
    rescue NoMethodError => e
      charities = [endowment]
    end

    charities.each do |charity|

      if charity.email.present?
        charity_message = {  
          :subject=> "[ giv2giv.org ] One of your endowments received a donation",
          :from_name=> "giv2giv.org",  
          :text=>"A giv2giv.org endowment that has your charity as a grant recipient has received a donation. Learn more at <a href=https://giv2giv.org/#endowment/#{endowment.slug}>#{endowment.name}</a>.",
          :to=>[  
           {  
             :email=> charity.email,
             :name=> charity.name  
           }  
          ],  
          :html=>"<h3>Donation Received!</h3><br /><hr />A giv2giv.org endowment that has your charity as a grant recipient has received a donation. Learn more at <a href=https://giv2giv.org/#endowment/#{endowment.slug}>#{endowment.name}</a>.<br>",
          :from_email=>"hello@giv2giv.org"  
        }
        sending = m.messages.send charity_message
      end
    end
  end

  def create_donor(email, donor_name)
    m= Mandrill::API.new  
    message = {  
     :subject=> "[ giv2giv.org ] Account created",  
     :from_name=> "giv2giv.org", 
     :text=>"Hello Kevin. #{donor_name} at #{email} just created an account at giv2giv.org",
     :to=>[ 
       {
         :email=>'kevin.pujanauski@giv2giv.org',
         :name=> 'Kevin Pujanauski'
       } 
     ],  
     :html=>"Hello Kevin. #{donor_name} at #{email} just created an account at giv2giv.org",
     :from_email=>"hello@giv2giv.org"  
    }  
    sending = m.messages.send message
    Rails.logger.debug sending
  end


  def endowment_grant_money(email, donor_name, grant_amount)
    m= Mandrill::API.new  
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
    sending = m.messages.send message
  end

  def forgot_password(donor)
    m= Mandrill::API.new  
    message = {  
     :subject=> "[ giv2giv.org ] Confirm your new password request",
     :from_name=> "giv2giv.org",  
     :text=>"Hello #{donor.name}. We received a request to change your password. If you did not request a password reset, ignore this email.  If you do wish to reset your password, click here to confirm: https://wwwtest.giv2giv.org/#reset_password?reset_token=#{donor.password_reset_token}",
     :to=>[
       {
         :email=> donor.email,
         :name=> donor.name
       }
     ],
     :html=>"Hello #{donor.name}. We received a request to change your password. If you did not request a password reset, ignore this email. <br /><br /> If you do wish to reset your password, click here to confirm: https://wwwtest.giv2giv.org/#reset_password?reset_token=#{donor.password_reset_token}",
     :from_email=>"hello@giv2giv.org"  
    }
    sending = m.messages.send message
  end

  def reset_password(donor)
    m= Mandrill::API.new  
    message = {  
     :subject=> "[ giv2giv.org ] Your new giv2giv.org password",
     :from_name=> "giv2giv.org",  
     :text=>"Hello #{donor.name}. You've successfully reset your password at giv2giv.org",
     :to=>[  
       {  
         :email=> donor.email
       }  
     ],  
     :html=>"Hello #{donor.name}. You've successfully reset your password at giv2giv.org <br />  Please log in at giv2giv.org to continue building a legacy!",
     :from_email=>"hello@giv2giv.org"  
    }  
    sending = m.messages.send message
  end

  def new_subscription(donor, endowment_name, type, amount, passthru_percent)
    m= Mandrill::API.new  
    message = {  
     :subject=> "[ giv2giv.org ] New subscription",
     :from_name=> "giv2giv.org",  
     :text=>"Hello giv2givers. We've got a new subscription! Donor #{donor.name} (#{donor.email}) started a "+type+" subscription to endowment #{endowment_name} at $#{amount}/month",
     :to=>[  
       {  
        :email => "kevinpuj@gmail.com",
        :name => "Kevin Pujanauski"
       },
       {
        :email => "tfmoor@gmail.com",
        :name => "Travis Moore"
       },
       {
        :email => "michael.blinn@giv2giv.org",
        :name => "Michael Blinn"
       }
     ],  
     :html=>"Hello giv2givers. We've got a new subscription! Donor #{donor.name} (#{donor.email} subscribed to endowment #{endowment_name} at #{amount}",
     :from_email=>"hello@giv2giv.org"  
    }  
    sending = m.messages.send message
  end

  def mail_invite(to_email, from_email)
    m= Mandrill::API.new
    message = {  
     :subject=> "[ giv2giv.org ] Invitation to giv2giv.org",
     :from_name=> "giv2giv.org",  
     :text=>"Hello! You've been invited to build a legacy at giv2giv.org by #{from_email}. Learn more at https://giv2giv.org",
     :to=>[
       {
         :email=> to_email
       }
     ],
     :html=>"Hello! You've been invited to build a legacy at giv2giv.org by #{from_email}. Learn more at https://giv2giv.org",
     :from_email=>from_email  
    }
    sending = m.messages.send message
  end

  

end
