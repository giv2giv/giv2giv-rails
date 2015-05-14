class Api::PaymentAccountsController < Api::BaseController
  skip_before_filter :require_authentication, :only => [:verify_knox]
  before_filter :current_payment_account, :except => [:index, :create, :verify_knox]
  skip_before_filter :current_payment_account, :only => [:all_donation_list, :cancel_subscription, :cancel_all_subscription]

  def index

    payment_accounts = current_donor.payment_accounts
    payment_accounts ||= []
    accounts_list = []

    payment_accounts.each do |account|
      if account.processor=='stripe'
        stripe_customer = Stripe::Customer.retrieve(account.stripe_cust_id)
        
        #  cards_list = []
        #  stripe_customer.cards.data.each do |card|
        #      cards_hash = [ card.id => {
        #        "type" => card.type,
        #        "last4" => card.last4,
        #        "exp_month" => card.exp_month,
        #        "exp_year" => card.exp_year
        #      } ]
        #      cards_list << cards_hash
        #
        #  end
        card = {
          "type" => stripe_customer.cards.data.last.type,
          "last4" => stripe_customer.cards.data.last.last4,
          "exp_month" => stripe_customer.cards.data.last.exp_month,
          "exp_year" => stripe_customer.cards.data.last.exp_year
        }
      end

      card = card || {
          "type" => "",
          "last4" => "",
          "exp_month" => "",
          "exp_year" => ""
        }

      accounts_hash = {
        "id" => account.id,
        "created_at" => account.created_at,
        "updated_at" => account.updated_at,
        "processor" => account.processor,
        "requires_reauth" => account.requires_reauth,
        "stripe_cust_id" => account.stripe_cust_id,
        "card_info" => card || {}
      }
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
        payment = PaymentAccount.new_stripe_account(set_token, current_donor.id, {:donor => current_donor, :processor => params[:processor]})
        render json: payment.to_json
      else
        render json: { :message => "Wrong parameters" }.to_json
      end
    end
  end

  def show
    respond_to do |format|
      if current_payment_account
        format.json { render json: current_payment_account }
      else
        format.json { head :not_found }
      end
    end
  end

  def destroy
    respond_to do |format|
      if current_payment_account

          subscription = DonorSubscription.where('payment_account_id=?',current_payment_account.id).destroy_all

          if current_payment_account.processor=='stripe'
            require "stripe"
            customer = Stripe::Customer.retrieve(current_payment_account.stripe_cust_id)
            customer.delete
          end
          
          current_payment_account.destroy       

          format.json { render json: { :message => "Payment account has been deleted" }.to_json }
      else
        format.json { head :not_found }
      end
    end
  end

  def donate_subscription
    respond_to do |format|
      if current_payment_account && donation = current_payment_account.stripe_charge('per-month',params[:amount], params[:endowment_id])
        format.json { render json: donation }
      else
        format.json { head :not_found }
      end
    end
  end

  def one_time_payment
    respond_to do |format|
      if current_payment_account
        if current_payment_account.processor=='stripe'
          donation = current_payment_account.stripe_charge('single_donation',params[:amount], params[:endowment_id])
        elsif current_payment_account.processor=='knox'
          donation = current_payment_account.knox_donation('single_donation', params[:amount], params[:endowment_id])
          Rails.logger.debug "Hello worldlast"
        end
        format.json { render json: donation }
       else
        format.json { head :not_found }
      end
    end
  end

  def donation_list
    respond_to do |format|
      if current_payment_account
        format.json { render json: current_payment_account.donations }
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
        cancel_subscription = PaymentAccount.cancel_subscription(current_donor, params[:id])
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

  def verify_knox
    require 'open-uri'
    require 'json'

    sess = Session.where('token=?', params[:token]).first

    if sess && params[:pst]=='Paid'
      knox_donor = Donor.where('id=?', sess.donor_id).first
      partner_key=App.knox['api_key']
      partner_password=App.knox['api_password']
      page = JSON.parse(open("https://knoxpayments.com/json/token.php?PARTNER_KEY="+partner_key+"&PARTNER_PASS="+partner_password+"&TRANS_ID="+params[:pay_id]+"&LIMIT_REQ=300").read())

      page=page["JSonDataResult"]

      payment_account = PaymentAccount.new_knox_account(knox_donor.id, {:donor => knox_donor, :processor => 'knox', :user_key => page["user_key"], :user_pass => page["user_pass"] })

#TODO
      if payment_account
        redirect_to "https://wwwtest.giv2giv.org/#donor"
      end
      
    end
  end

  protected

  def current_payment_account
    current_donor.payment_accounts.find(params[:id])
  end

end
