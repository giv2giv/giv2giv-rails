class DonorMailer < ActionMailer::Base
  default :from => "no-reply@giv2giv.org"
  
  def charge_success(email, data)
    mail(:to => email, :subject => "[ Giv2Giv ] Thank you for your donation", content_type: "text/html", :body => "<h3>Charge Successful</h3><br /><hr />Thank you for your donation<br><br> DETAIL DATA : <br><br>#{data}")
  end

  def charity_group_grant_money(email, charity_name, donor_name, grant_amount)
    mail(:to => email, :subject => "[ Giv2Giv ] Congratulation, Charity Group #{charity_name} Grant Out Money", content_type: "text/html", :body => "Hello #{donor_name}. We just granted $#{grant_amount} out to charities on behalf of you and other donors at giv2giv. Want to see the breakdown by charity_group or charity? Visit giv2giv.org")
  end
end