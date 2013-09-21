class DonorMailer < ActionMailer::Base
  default :from => "notifications@example.com"
  
  def charge_success(user)
    mail(:to => user.email, :subject => "[ Giv2Giv ] Thank you for your donation")
  end
end