class ErrorJobMailer < ActionMailer::Base
  default :from => "no-reply@giv2giv.org"
  
  def error_priceshare(email)
    mail(:to => email, :subject => "[ Giv2Giv ] Error Calculation For Priceshare", content_type: "text/html", :body => "<h3>Calculation Price Error</h3><br /><hr />Date : #{DateTime.now}")
  end

  def error_grantshare(email)
    mail(:to => email, :subject => "[ Giv2Giv ] Error Calculation For Grantshare", content_type: "text/html", :body => "<h3>Calculation Grant Error</h3><br /><hr />Date : #{DateTime.now}")
  end

end