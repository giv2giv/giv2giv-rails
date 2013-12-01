class Api::DonorsController < Api::BaseController
  skip_before_filter :require_authentication, :only => [:create, :forgot_password, :reset_password, :balance_information]

  def create
    donor = Donor.new(params[:donor])
    donor.type_donor = "registered"
    donor.password = secure_password(params[:donor][:password])

    respond_to do |format|
      if donor.save
        format.json { render json: donor, status: :created }
      else
        format.json { render json: donor.errors, status: :unprocessable_entity }
      end
    end
  end

  def balance_information
    if defined? current_donor
      last_donation_price = Share.last.donation_price rescue 0.0
      share_balance = BigDecimal("#{current_donor.donations.sum(:shares_added)}") - BigDecimal("#{current_donor.donor_grants.sum(:shares_subtracted)}")
      donor_current_balance = ((BigDecimal("#{share_balance}") * BigDecimal("#{last_donation_price}")) * 10).ceil / 10.0
      donor_total_donations = current_donor.donations.sum(:gross_amount)
      donor_total_grants = current_donor.donor_grants.where("status = ?", 'sent').sum(:gross_amount)
    else
      donor_current_balance = "0.0"
      donor_total_donations = "0.0"
      donor_total_grants = "0.0"
    end

    giv2giv_share_balance = BigDecimal("#{Donation.sum(:shares_added)}") - BigDecimal("#{CharityGrant.sum(:shares_subtracted)}")
    giv2giv_current_balance = ((BigDecimal("#{giv2giv_share_balance}") * BigDecimal("#{last_donation_price}")) * 10).ceil / 10.0
    giv2giv_total_donations = Donation.sum(:gross_amount)
    giv2giv_total_grants = CharityGrant.where("status = ?", 'sent').sum(:gross_amount)

    render json: { :donor_current_balance => donor_current_balance, :donor_total_donations => donor_total_donations, :donor_total_grants => donor_total_grants, :giv2giv_current_balance => giv2giv_current_balance, :giv2giv_total_donations => giv2giv_total_donations, :giv2giv_total_grants => giv2giv_total_grants }.to_json
  end

  def subscriptions
    last_grant_price = Share.last.grant_price rescue 0.0
    subscriptions = current_donor.donor_subscriptions
    subscriptions_list = []
    subscriptions.each do |subscription|
      #Better to include Endowment.where("endowment_id = ?", subscription.endowment_id).my_balances and endowment.global_balances
      subscriptions_hash = [ subscription.stripe_subscription_id => {
        "endowment_name" => Endowment.where("endowment_id = ?", subscription.endowment_id).name,
        "endowment_donation_amount" => subscription.gross_amount,
        "endowment_donor_count" => Donation.where("endowment_id = ?", subscription.endowment_id).count('donor_id', :distinct => true),
        "endowment_donor_total_donations" => current_donor.donations.where("endowment_id = ?", subscription.endowment_id).sum(:gross_amount),
        "endowment_total_donations" => Donation.where("endowment_id = ?", subscription.endowment_id).sum(:gross_amount),
        "endowment_donor_current_balance" => ((BigDecimal(current_donor.donations.where("endowment_id = ?", subscription.endowment_id).sum(:shares_added)) - BigDecimal(current_donor.donor_grants.sum(:shares_subtracted))) * last_grant_price * 10).ceil / 10.0,
        "endowment_total_balance" => ((BigDecimal(Donation.where("endowment_id = ?", subscription.endowment_id).sum(:shares_added)) - BigDecimal(current_donor.donor_grants.where("endowment_id = ?", subscription.endowment_id).sum(:shares_subtracted))) * last_grant_price * 10).ceil / 10.0,
        "total_granted_by_donor" => current_donor.donor_grants.where("status = ?", 'sent').where("endowment_id = ?", subscription.endowment_id),#.sum(:grant_amount),
        "total_granted_from_endowment" => DonorGrant.where("status = ?", 'sent').where("endowment_id = ?", subscription.endowment_id)#.sum(:grant_amount)
      }
    ]
    subscriptions_list << subscriptions_hash
  end
  render json: subscriptions_list
end

def update
  donor = current_donor

  respond_to do |format|
    if donor && donor.update_attributes(params[:donor])
      format.json { render json: donor }
    else
      format.json { render json: donor.errors, status: :unprocessable_entity }
    end
  end
end

def show
  respond_to do |format|
    format.json { render json: current_donor }
  end
end

def forgot_password
  donor = Donor.find_by_email(params[:email])
  donor.send_password_reset if donor
  render json: { :message => "Email sent with password reset instructions" }.to_json
end

def reset_password
  donor = Donor.find_by_password_reset_token!(params[:reset_token])

  if donor
    unless donor.expire_password_reset < 2.hours.ago
      new_password = SecureRandom.base64(6)
      if donor.update_attributes(password: secure_password(new_password))
        DonorMailer.reset_password(donor.email, new_password).deliver
        message = "Your new password has been sent to your email"
      else
        message = "Failed to reset password"
      end
    else
      message = "Password reset has expired"
    end
    render json: { :message => message }.to_json
  else
    render json: { :message => "Password reset has expired or not exist." }.to_json
  end

end

def donations
      respond_to do |format|
        if params.has_key?(:start_date) and params.has_key?(:end_date) and params.has_key?(:endowment_id)
          format.json { render json: { :donations => current_donor.donations.where("endowment_id = ? AND DATE(donations.created_at) between ? AND ?", params[:endowment_id], params[:start_date], params[:end_date]), :total => current_donor.donations.where("endowment_id = ? AND DATE(donations.created_at) between ? AND ?", params[:endowment_id], params[:start_date], params[:end_date]).sum(:gross_amount) } }
        elsif params.has_key?(:start_date)
          format.json { render json: { :donations => current_donor.donations.where("DATE(donations.created_at) > ?", params[:start_date]), :total => current_donor.donations.where("DATE(donations.created_at) > ?", params[:start_date]).sum(:gross_amount) } }
        elsif params.has_key?(:start_date) and params.has_key?(:end_date)
          format.json { render json: { :donations => current_donor.donations.where("DATE(donations.created_at) between ? AND ?", params[:start_date], params[:end_date]), :total => current_donor.donations.where("DATE(donations.created_at) between ? AND ?", params[:start_date], params[:end_date]).sum(:gross_amount) } }
        elsif params.has_key?(:endowment_id)
          format.json { render json: { :donations => current_donor.donations.where("endowment_id = ?", params[:endowment_id]), :total =>current_donor.donations.where("endowment_id = ?", params[:endowment_id]).sum(:gross_amount) } }
        else
          format.json { render json: current_donor.donations.all.order('donations.created_at asc') }
        end
      end
    end
  end

