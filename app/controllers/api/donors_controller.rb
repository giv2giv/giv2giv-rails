class Api::DonorsController < Api::BaseController
  skip_before_filter :require_authentication, :only => [:create, :forgot_password, :reset_password, :balance_information]


  def create

    donor = Donor.new(params[:donor])
    donor.type_donor = "registered"
    donor.password = secure_password(params[:donor][:password])
    if params[:accepted_terms]
      donor.accepted_terms = true
      donor.accepted_terms_on = DateTime.now      
    end

    respond_to do |format|
      if donor.save
        #DonorMailer.create_donor(donor.email).deliver
        format.json { render json: donor, status: :created }
      else
        format.json { render json: donor.errors, status: :unprocessable_entity }
      end
    end

  end

  def balance_information
    last_donation_price = Share.last.donation_price rescue 0.0

    if defined? current_donor.id
      share_balance = BigDecimal("#{current_donor.donations.sum(:shares_added)}") - BigDecimal("#{current_donor.donor_grants.sum(:shares_subtracted)}")
      donor_current_balance = ((BigDecimal("#{share_balance}") * BigDecimal("#{last_donation_price}")) * 10).ceil / 10.0
      donor_total_donations = current_donor.donations.sum(:gross_amount)
      donor_total_grants = current_donor.donor_grants.where("status = ?", 'sent').sum(:gross_amount).to_f
    else
      donor_current_balance = 0.0
      donor_total_donations = 0.0
      donor_total_grants = 0.0
    end

    giv2giv_share_balance = BigDecimal("#{Donation.sum(:shares_added)}") - BigDecimal("#{CharityGrant.sum(:shares_subtracted)}")
    giv2giv_current_balance = ((BigDecimal("#{giv2giv_share_balance}") * BigDecimal("#{last_donation_price}")) * 10).ceil / 10.0
    giv2giv_total_donations = Donation.sum(:gross_amount)
    giv2giv_total_grants = CharityGrant.where("status = ?", 'sent').sum(:gross_amount)

    render json: { :donor_current_balance => donor_current_balance, :donor_total_donations => donor_total_donations, :donor_total_grants => donor_total_grants, :giv2giv_current_balance => giv2giv_current_balance, :giv2giv_total_donations => giv2giv_total_donations, :giv2giv_total_grants => giv2giv_total_grants }.to_json
  end

  def subscriptions
    last_donation_price = Share.last.donation_price rescue 0.0
    subscriptions = current_donor.donor_subscriptions.where("canceled_at IS NULL OR canceled_at = ?", false)
    subscriptions ||= []
    subscriptions_list = []
    
    subscriptions.each do |subscription|
      #Better to include Endowment.where("endowment_id = ?", subscription.endowment_id).my_balances and endowment.global_balances
      endowment = Endowment.find(subscription.endowment_id)

      subscriptions_hash = {
        "subscription_id" => subscription.id,
        "endowment_id" => endowment.id,
        "created_at" => endowment.created_at,
        "updated_at" => endowment.updated_at,
        "name" => endowment.name,
        "description" => endowment.description,
        "minimum_donation_amount" => subscription.gross_amount,
        "my_balances" => current_donor.my_balances(endowment.id),
        "global_balances" => endowment.global_balances,
        "charities" => endowment.charities
      }
      subscriptions_list << subscriptions_hash
    end
    render json: subscriptions_list
  end

  
  def update
    donor = current_donor
    respond_to do |format|

      if donor && donor.id
        donor.update_attributes(params[:donor].except(:accepted_terms, :password))
        if params.has_key?(:password) 
          donor.update_attributes(password: secure_password(params[:password]))
        end
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
        format.json { render json: { :timestamp => Time.new.to_i, :donations => current_donor.donations.where("endowment_id = ? AND DATE(donations.created_at) between ? AND ?", params[:endowment_id], params[:start_date], params[:end_date]), :total => current_donor.donations.where("endowment_id = ? AND DATE(donations.created_at) between ? AND ?", params[:endowment_id], params[:start_date], params[:end_date]).sum(:gross_amount) } }
      elsif params.has_key?(:start_date)
        format.json { render json: { :timestamp => Time.new.to_i, :donations => current_donor.donations.where("DATE(donations.created_at) > ?", params[:start_date]), :total => current_donor.donations.where("DATE(donations.created_at) > ?", params[:start_date]).sum(:gross_amount) } }
      elsif params.has_key?(:start_date) and params.has_key?(:end_date)
        format.json { render json: { :timestamp => Time.new.to_i, :donations => current_donor.donations.where("DATE(donations.created_at) between ? AND ?", params[:start_date], params[:end_date]), :total => current_donor.donations.where("DATE(donations.created_at) between ? AND ?", params[:start_date], params[:end_date]).sum(:gross_amount) } }
      elsif params.has_key?(:endowment_id)
        format.json { render json: { :timestamp => Time.new.to_i, :donations => current_donor.donations.where("endowment_id = ?", params[:endowment_id]), :total =>current_donor.donations.where("endowment_id = ?", params[:endowment_id]).sum(:gross_amount) } }
      else
        format.json { render json: { :timestamp => Time.new.to_i, :donations => current_donor.donations.all.order('donations.created_at asc'), :total => current_donor.donations.all.sum(:gross_amount) } }
      end
    end
  end

end

