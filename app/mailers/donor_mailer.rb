class DonorMailer < ActionMailer::Base
  default :from => "no-reply@giv2giv.org"
  
  def charge_success(email, donation_amount)
    mail(:to => email, :subject => "[ giv2giv.org ] Thank you for your donation", content_type: "text/html", :body => "<h3>Charge Successful</h3><br /><hr />Thank you for your donation of #{donation_amount} to giv2giv.org. Want to see the breakdown by endowment or charity? Visit giv2giv.org<br><br>")
  end

  def endowment_grant_money(email, donor_name, grant_amount)
    mail(:to => email, :subject => "[ giv2giv.org ] Grant sent", content_type: "text/html", :body => "Hello #{donor_name}. We just granted $#{grant_amount} out to charities on behalf of you and other donors at giv2giv. Want to see the breakdown by endowment or charity? Visit giv2giv.org")
  end

  def grant_fee_transfer(email, from_etrade_to_dwolla_transaction_id, total_giv2giv_fee)
    mail(:to => email, :subject => "[ giv2giv.org ] #{Date.today} Grant Fee Transfer", content_type: "text/html", :body => "  Transfer of $#{total_giv2giv_fee} from eTrade to Dwolla requested. From etrade to Dwolla ID: #{from_etrade_to_dwolla_transaction_id}")    
  end

  def grant_transfer_requested(email, from_dwolla_to_giv2giv_transaction_id, from_etrade_to_dwolla_transaction_id, total_giv2giv_fee)
    mail(:to => email, :subject => "[ giv2giv.org ] #{Date.today} Grant Fee Transfer", content_type: "text/html", :body => "  Transfer of $#{total_giv2giv_fee} from Dwolla to giv2giv requested. From etrade to Dwolla ID: #{from_etrade_to_dwolla_transaction_id}<br>From Dwolla to giv2giv ID: #{from_dwolla_to_giv2giv_transaction_id} ")    
  end

  def forgot_password(donor)
    mail(:to => donor.email, :subject => "[ giv2giv.org ] New Password", content_type: "text/html", :body => "Url reset password : https://api.giv2giv.org/api/donors/reset_password.json?reset_token=#{donor.password_reset_token}")    
  end

  def reset_password(email, new_password)
    mail(:to => email, :subject => "[ giv2giv.org ] New Password", content_type: "text/html", :body => "Your new password is : #{new_password}")    
  end

end
