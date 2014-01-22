class Api::PaymentAccountsController < Api::BaseController
  before_filter :current_donor_id, :except => [:index, :create, :one_time_payment]
  skip_before_filter :current_donor_id, :only => [:all_donation_list, :cancel_subscription, :cancel_all_subscription]
  skip_before_filter :require_authentication, :only => :one_time_payment

  def index

    payment_accounts = current_donor.payment_accounts
    payment_accounts ||= []
    accounts_list = []

    payment_accounts.each do |account|
      stripe_customer = Stripe::Customer.retrieve(account.stripe_cust_id)

      cards_list = []
      stripe_customer.cards.data.each do |card|
        cards_hash = [ card.id => {
          "type" => card.type,
          "last4" => card.last4,
          "exp_month" => card.exp_month,
          "exp_year" => card.exp_year
        } ]
        cards_list << cards_hash
      end

      accounts_hash = [ account.id => {
        "created_at" => account.created_at,
        "updated_at" => account.updated_at,
        "processor" => account.processor,
        "requires_reauth" => account.requires_reauth,
        "stripe_cust_id" => account.stripe_cust_id,
	"cards" => cards_list
      } ]
      accounts_list << accounts_hash
    end

    render json: accounts_list

  end

  def create
    set_token = params[:stripeToken]

    if set_token.blank?
      render json: { :message => "Please provide your stripe token" }.to_json
    else
      if params.has_key?(:processor)
        payment = PaymentAccount.new_account(set_token, current_donor.id, {:donor => current_donor, :processor => params[:processor]})
        render json: payment.to_json
      else
        render json: { :message => "Wrong parameters" }.to_json
      end
    end
  end

  def update
    set_token = params[:stripeToken]
    if set_token.blank?
      render json: { :message => "Please provide your stripe token"}.to_json
    else
      params[:payment_account] = {"processor"=> params[:processor]}#, "stripeToken"=> params[:stripeToken]}

      if params.has_key?(:payment_account)
        payment = PaymentAccount.update_account(set_token, current_donor.id, current_donor_id, {:donor => current_donor}.merge(params[:payment_account]))

        respond_to do |format|
          if current_donor_id && current_donor_id.update_attributes(params[:payment_account])
            format.json { render json: current_donor_id }
          elsif current_donor_id
            format.json { render json: current_donor_id.errors, status: :unprocessable_entity }
          else
            format.json { head :not_found }
          end
        end

      else
        render json: {:message => "Wrong parameters"}.to_json
      end
    end
  end

  def show
    respond_to do |format|
      if current_donor_id
        format.json { render json: current_donor_id }
      else
        format.json { head :not_found }
      end
    end

  end

  def destroy
    respond_to do |format|
      if current_donor_id
        account = current_donor.payment_accounts.find(params[:id])
        account.destroy
        format.json { render json: { :message => "Payment account has been deleted" }.to_json }
      else
        format.json { head :not_found }
      end
    end
  end

  def donate_subscription
    respond_to do |format|
      if current_donor_id && donation = current_donor_id.donate_subscription(params[:amount], params[:endowment_id], params[:id], current_donor.email)
        format.json { render json: donation }
      else
        format.json { head :not_found }
      end
    end
  end

  def one_time_payment
    if params.has_key?(:password)
      password = secure_password(params[:password])
    else
      password = params[:password]
    end

    respond_to do |format|
      donation = PaymentAccount.one_time_payment(params[:amount].to_i, params[:endowment_id], params[:email], params[:stripeToken], params[:payment_account_id], password)
      format.json { render json: donation }
    end
  end

  def donation_list
    respond_to do |format|
      if current_donor_id
        format.json { render json: current_donor_id.donations }
      else
        format.json { head :not_found }
      end
    end
  end

  def all_donation_list
    if current_donor
      respond_to do |format|
        if params.has_key?(:start_date) and params.has_key?(:end_date) and params.has_key?(:endowment_id)
          format.json { render json: { :donations => current_donor.donations.where("endowment_id = ? AND DATE(donations.created_at) between ? AND ?", params[:endowment_id], params[:start_date], params[:end_date]), :total => current_donor.donations.where("endowment_id = ? AND DATE(donations.created_at) between ? AND ?", params[:endowment_id], params[:start_date], params[:end_date]).sum(:gross_amount) } }
        elsif params.has_key?(:start_date) and params.has_key?(:end_date)
          format.json { render json: { :donations => current_donor.donations.where("DATE(donations.created_at) between ? AND ?", params[:start_date], params[:end_date]), :total => current_donor.donations.where("DATE(donations.created_at) between ? AND ?", params[:start_date], params[:end_date]).sum(:gross_amount) } }
        elsif params.has_key?(:endowment_id)
          format.json { render json: { :donations => current_donor.donations.where("endowment_id = ?", params[:endowment_id]), :total =>current_donor.donor_subscriptions.where("endowment_id = ?", params[:endowment_id]).sum(:gross_amount) } }
        else
          donor_payment_accounts = current_donor.payment_accounts.all
          donation_data = []
          donor_payment_accounts.each do |payment_account|
            donation_data << payment_account.donations
            # donation_data << payment_account.donor_subscriptions
          end
          format.json { render json: donation_data }
        end
      end
    else
      render :json => { :message => "unauthorized" }.to_json
    end
  end

  def cancel_subscription
    if current_donor
      respond_to do |format|
        cancel_subscription = PaymentAccount.cancel_subscription(params[:id])
        format.json { render json: cancel_subscription }
      end
    else
      render :json => {:message => "unauthorized"}.to_json
    end
  end

  def cancel_all_subscription
    if current_donor
      respond_to do |format|
        cancel_all_subscription = PaymentAccount.cancel_all_subscription(current_donor)
        format.json { render json: cancel_all_subscription }
      end
    else
      render :json => {:message => "unauthorized"}.to_json
    end
  end

  protected

  def current_donor_id
    current_donor.payment_accounts.find(params[:id])
  end

end
