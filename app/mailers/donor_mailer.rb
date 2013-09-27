class DonorMailer < ActionMailer::Base
  default :from => "no-reply@giv2giv.org"
  
  def charge_success(user)
    mail(:to => user, :subject => "[ Giv2Giv ] Thank you for your donation", content_type: "text/html", :body => "<h3>Charge Successful</h3><br /><hr />Thank you for your donation")
  end

end