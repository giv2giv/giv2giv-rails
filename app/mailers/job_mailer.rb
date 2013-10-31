class JobMailer < ActionMailer::Base
  default :from => "no-reply@giv2giv.org"
  
  def success_compute(email, action)
    mail(:to => email, :subject => "[ Giv2Giv ] Success #{action}", content_type: "text/html", :body => "<h3>Calculation success in #{action}</h3><br /><hr />Date : #{DateTime.now}")
  end

  def success_job_scheduler(email, action)
    mail(:to => email, :subject => "[ Giv2Giv ] success execute #{action}", content_type: "text/html", :body => "<h3>Calculation Success in #{action}</h3><br /><hr />Date : #{DateTime.now}")
  end

end
