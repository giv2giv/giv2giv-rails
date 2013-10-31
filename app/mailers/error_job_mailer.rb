class ErrorJobMailer < ActionMailer::Base
  default :from => "no-reply@giv2giv.org"
  
  def error_compute_share_price(email)
    mail(:to => email, :subject => "[ Giv2Giv ] Error Calculation error in compute_share_price", content_type: "text/html", :body => "<h3>Calculation error in compute_share_price</h3><br /><hr />Date : #{DateTime.now}")
  end

  def error_grant_step_1(email)
    mail(:to => email, :subject => "[ Giv2Giv ] Calculation error in grant_step_1", content_type: "text/html", :body => "<h3>Calculation error in grant_step_1</h3><br /><hr />Date : #{DateTime.now}")
  end

end
