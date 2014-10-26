class Api::DonorsController < Api::BaseController
  skip_before_filter :require_authentication, :only => [:create, :forgot_password, :reset_password, :balance_information]

  def create

    donor = Donor.new(donor_params)
    donor.type_donor = "registered"
    donor.password = secure_password(params[:donor][:password])
    if params[:accepted_terms]==true
      donor.accepted_terms = true
      donor.accepted_terms_on = DateTime.now      
    end

    respond_to do |format|
      if donor.save
        DonorMailer.create_donor(donor.email, donor.name)
        require 'gibbon'
        gb = Gibbon::API.new(App.mailer['mailchimp_key'])
        gb.lists.subscribe({:id => App.mailer['mailchimp_list_id'], :email => {:email => donor.email}, :merge_vars => {:FNAME => donor.name}, :double_optin => false})
        invite = Invite.where("hash_token = ?", params[:hash_token])
        if invite
          invite.accepted = true
          invite.save!
        end

        format.json { render json: donor, status: :created }
      else
        format.json { render json: donor.errors, status: :unprocessable_entity }
      end
    end

  end

  def send_invite
    respond_to do |format|
      if(params.has_key?(:email]))
        invite = Invite.new()
        invite.donor_id = current_donor.id
        invite.email = params[:email]
        invite.hash_token = SecureRandom.uuid
        invite.accepted = false
      end
      if invite.save
        DonorMailer.mail_invite(params[:email], current_donor.email)
        format.json { render json: invite, status: :created }
      else
        format.json { render json: {:message => "unauthorized"}.to_json, status: :unprocessable_entity }
      end
    end

  end

  def balance_information
    last_donation_price = Share.last.donation_price rescue 0.0
    if current_donor && current_donor.id
      share_balance = BigDecimal("#{current_donor.donations.sum(:shares_added)}") - BigDecimal("#{current_donor.grants.where("(status = ? OR status = ?)", 'accepted', 'pending_acceptance').sum(:shares_subtracted)}")
      donor_current_balance = (BigDecimal("#{share_balance}") * BigDecimal("#{last_donation_price}")).floor2(2)
      donor_total_amount_of_donations = current_donor.donations.sum(:gross_amount).to_f
      donor_total_amount_of_grants = current_donor.grants.where("(status = ? OR status = ?)", 'accepted', 'pending_acceptance').sum(:grant_amount).to_f
      donor_total_amount_of_pending_grants = current_donor.grants.where("(status = ? OR status = ?)", 'pending_acceptance', 'pending_approval').sum(:grant_amount).to_f
      donor_total_number_of_pending_grants = current_donor.grants.where("(status = ? OR status = ?)", 'pending_acceptance', 'pending_approval').count
      donor_balance_history = (donor_first_donation_date..Date.today).select {|d| (d.day % 7 ) == 0 || d==Date.today}.map { |date| {"date"=>date, "balance"=>donor_balance_on(date)} }
      donor_active_subscriptions = current_donor.donor_subscriptions.where("canceled_at IS NULL OR canceled_at = ?", false).sum(:gross_amount).floor2(2)
    else
      donor_current_balance = 0.0
      donor_total_amount_of_donations = 0.0
      donor_total_amount_of_grants = 0.0
      donor_total_number_of_pending_grants = 0.0
      donor_total_amount_of_pending_grants = 0.0
      donor_balance_history = 0
      donor_active_subscriptions = 0
    end

    current_fund_balance_all_donors = global_balance_on(Date.today)

    total_number_of_donors = Donation.count('donor_id', :distinct => true)
    total_number_of_endowments = Endowment.count

    total_active_subscriptions = DonorSubscription.where("canceled_at IS NULL OR canceled_at = ?", false).count    
    total_monthly_donations = DonorSubscription.where("canceled_at IS NULL OR canceled_at = ?", false).sum(:gross_amount).floor2(2)

    total_number_of_donations = Donation.count
    total_amount_of_donations = Donation.sum(:gross_amount).to_f

    global_balance_history = (global_first_donation_date..Date.today).select {|d| (d.day % 7) == 0 || d==Date.today}.map { |date| {"date"=>date, "balance"=> global_balance_on(date)} }

    total_number_of_grants = Grant.where("(status = ? OR status = ?)", 'accepted', 'pending_acceptance').count
    total_amount_of_grants = Grant.where("(status = ? OR status = ?)", 'accepted', 'pending_acceptance').sum(:grant_amount).to_f
    total_number_of_pending_grants = Grant.where("(status = ? OR status = ?)", 'pending_acceptance', 'pending_approval').count
    total_amount_of_pending_grants = Grant.where("(status = ? OR status = ?)", 'pending_acceptance', 'pending_approval').sum(:grant_amount).to_f

    if total_amount_of_grants==0.0
      total_amount_of_grants=0
    end

    render json: {  :donor_current_balance => donor_current_balance,
                    :donor_active_subscriptions => donor_active_subscriptions,
                    :total_active_subscriptions => total_active_subscriptions,
                    :total_monthly_donations => total_monthly_donations,
                    :donor_total_amount_of_donations => donor_total_amount_of_donations,
                    :donor_total_amount_of_grants => donor_total_amount_of_grants,
                    :donor_total_number_of_pending_grants => donor_total_number_of_pending_grants,
                    :donor_total_amount_of_pending_grants => donor_total_amount_of_pending_grants,
                    :total_number_of_donors => total_number_of_donors,
                    :total_number_of_endowments => total_number_of_endowments,
                    :current_fund_balance_all_donors => current_fund_balance_all_donors,
                    :total_number_of_donations => total_number_of_donations,
                    :total_amount_of_donations => total_amount_of_donations,
                    :total_number_of_grants => total_number_of_grants,
                    :total_amount_of_grants => total_amount_of_grants,
                    :total_number_of_pending_grants => total_number_of_pending_grants,
                    :total_amount_of_pending_grants => total_amount_of_pending_grants,
                    :donor_balance_history => donor_balance_history || 0,
                    :donor_projected_balance => CalculationShare::Calculation.project_amount( {:principal=>donor_current_balance,:monthly_addition=>donor_active_subscriptions} ),
                    :global_balance_history => global_balance_history || 0,
                    :global_projected_balance => CalculationShare::Calculation.project_amount( {:principal=>current_fund_balance_all_donors,:monthly_addition=>total_monthly_donations} )
                  }.to_json
  end

  def subscriptions

    if params.has_key?(:current_only)
      subscriptions = current_donor.donor_subscriptions.where("canceled_at IS NULL")
    else
      subscriptions = current_donor.donor_subscriptions
    end

    if params.has_key?(:group)
      subscriptions = subscriptions.group(:endowment_id)
    end

    subscriptions ||= []
    subscriptions_list = []
    
    subscriptions.each do |subscription|
      #Better to include Endowment.where("endowment_id = ?", subscription.endowment_id).my_balances and endowment.global_balances
      endowment = Endowment.find(subscription.endowment_id)

      subscriptions_hash = {
        "subscription_id" => subscription.id,
        "id" => endowment.id,
        "created_at" => endowment.created_at,
        "updated_at" => endowment.updated_at,
        "canceled_at" => subscription.canceled_at,
        "name" => endowment.name,
        "slug" => endowment.slug,
        "description" => endowment.description,
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
        donor.update_attributes(donor_params)#params[:donor].except(:accepted_terms, :password))
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
    gb = Gibbon::API.new(App.mailer['mailchimp_key'])

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
    if donor && params[:password]
      unless donor.expire_password_reset < 2.hours.ago
        donor.password = secure_password(params[:password])
        donor.password_reset_token = nil
        donor.save!
        DonorMailer.reset_password(donor).deliver
        message = "Password successfully reset"
      else
        message = "Password reset has expired"
      end
      render json: { :message => message }.to_json
    else
      render json: { :message => "Invalid token." }.to_json
    end
  end

  def subscribe
    gb = Gibbon::API.new(App.mailer['mailchimp_key'])
    gb.lists.subscribe({:id => App.mailer['mailchimp_list_id'], :email => {:email => current_donor.email}, :merge_vars => {:FNAME => current_donor.name}, :double_optin => false})
    current_donor.subscribed=true
    current_donor.save!
    render json: { :message => "Subscribed." }.to_json
  end
  def unsubscribe
    gb = Gibbon::API.new(App.mailer['mailchimp_key'])
    gb.lists.unsubscribe({:id => App.mailer['mailchimp_list_id'], :email => {:email => current_donor.email}, :delete_member => true, :send_notify => true})
    current_donor.subscribed=false
    current_donor.save!
    render json: { :message => "Unsubscribed." }.to_json
  end

  def donations
 
    donations ||= []
    donations_list = []

    if params.has_key?(:start_date) && params.has_key?(:end_date) && params.has_key?(:endowment_id)
      donations = current_donor.donations.where("endowment_id = ? AND DATE(donations.created_at) between ? AND ?", params[:endowment_id], params[:start_date], params[:end_date])
    elsif params.has_key?(:start_date) && params.has_key?(:end_date)
      donations = current_donor.donations.where("DATE(donations.created_at) between ? AND ?", params[:start_date], params[:end_date])
    elsif params.has_key?(:start_date)
      donations = current_donor.donations.where("DATE(donations.created_at) > ?", params[:start_date])
    elsif params.has_key?(:endowment_id)
      donations = current_donor.donations.where("endowment_id = ?", params[:endowment_id])
    else
      donations = current_donor.donations.order("created_at ASC")
    end

    total = donations.sum(:gross_amount) || 0.0


    donations.each do |donation|
      donations_hash = {
          "donation_id" => donation.id,
          "donor_id" => donation.donor_id,
          "endowment_id" => donation.endowment_id,
          "endowment_name" => Endowment.find(donation.endowment_id).name,
          "payment_account_id" => donation.payment_account_id,
          "created_at" => donation.created_at,
          "transaction_fee" => donation.transaction_fee,
          "gross_amount" => donation.gross_amount.to_f,
          "net_amount" => donation.net_amount.to_f
      }
      
      donations_list << donations_hash
    
    end
    render json: { :donations => donations_list, :total => total.to_f, :timestamp => Time.new.to_i, }
  end
end

def global_first_donation_date
  Donation.order("created_at ASC").first.created_at.to_date rescue Date.today
end
def donor_first_donation_date
  current_donor.donations.order("created_at ASC").first.created_at.to_date rescue Date.today
end

def global_balance_on(date)
  last_donation_price = Share.last.donation_price rescue 0.0
  dt = DateTime.parse(date.to_s)
  dt = dt + 11.hours + 59.minutes + 59.seconds
  donated_shares = Donation.where("created_at <= ?", dt).sum(:shares_added) rescue 0.0
  granted_shares = Grant.where("created_at <= ? AND (status = ? OR status = ?)", dt, 'accepted', 'pending_acceptance').sum(:shares_subtracted) rescue 0.0
  (last_donation_price * (donated_shares - granted_shares)).floor2(2)
end

def donor_balance_on(date)
  last_donation_price = Share.last.donation_price rescue 0.0
  dt = DateTime.parse(date.to_s)
  dt = dt + 11.hours + 59.minutes + 59.seconds
  donated_shares = current_donor.donations.where("created_at <= ?", dt).sum(:shares_added) rescue 0.0
  granted_shares = current_donor.grants.where("created_at <= ? AND (status = ? OR status = ?)", dt, 'accepted', 'pending_acceptance').sum(:shares_subtracted) rescue 0.0
  (last_donation_price * (donated_shares - granted_shares)).floor2(2)
end

private
  def donor_params
    allow = [:name, :email, :password, :accepted_terms, :address, :city, :country, :phone_number, :zip]
    params.require(:donor).permit(allow)
  end