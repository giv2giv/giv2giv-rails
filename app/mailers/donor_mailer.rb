class DonorMailer < ActionMailer::Base
  default :from => "no-reply@giv2giv.org"
  
  def charge_success(email, data)
    mail(:to => email, :subject => "[ Giv2Giv ] Thank you for your donation", content_type: "text/html", :body => "<h3>Charge Successful</h3><br /><hr />Thank you for your donation<br><br> DETAIL DATA : <br><br>#{data}")
  end

  def charity_group_grant_money(email, charity_name, donor_name, grant_amount)
    mail(:to => email, :subject => "[ Giv2Giv ] Congratulation, Charity Group #{charity_name} Grant Out Money", content_type: "text/html", :body => "Hello #{donor_name}. We just granted $#{grant_amount} out to charities on behalf of you and other donors at giv2giv. Want to see the breakdown by charity_group or charity? Visit giv2giv.org")
  end

  def grant_fee_transfer(email, from_etrade_to_dwolla_transaction_id, total_giv2giv_fee)
    mail(:to => email, :subject => "#{Date.today} Grant Fee Transfer", content_type: "text/html", :body => "  Transfer of $#{total_giv2giv_fee} from eTrade to Dwolla requested. From etrade to Dwolla ID: #{from_etrade_to_dwolla_transaction_id}")    
  end

end