class Api::PaymentAccountsController < Api::BaseController
  include StripeHelper
  
  before_filter :current_donor_id, :except => [:index, :create, :show_token_info, :show_data_subscription, :cancel_donate_subscription]

  def index
    pas = current_donor.payment_accounts

    respond_to do |format|
      format.json { render json: pas }
    end
  end

  def create
    if params.has_key?(:payment_account)
      payment = PaymentAccount.new({:donor => current_donor}.merge(params[:payment_account]))
      respond_to do |format|
        if payment.save
          format.json { render json: payment, status: :created }
        else
          format.json { render json: payment.errors, status: :unprocessable_entity }
        end
      end
    else
      render json: {:message => "Wrong parameters"}.to_json
    end
  end

  def update
    if params.has_key?(:payment_account)
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
        current_donor_id.destroy
        render json: {:message => "Payment account has been delete"}.to_json
      else
        format.json { head :not_found }
      end
    end
  end

  def donate_subscription
    if(params.has_key?(:number) && params.has_key?(:exp_month) && params.has_key?(:exp_year) && params.has_key?(:cvc))
      set_token = PaymentAccount.new_payment(params)
      if set_token.id.empty?
        render json: {:message => "Failed create payment account"}.to_json
      else
        respond_to do |format|
          if current_donor_id && donation = current_donor_id.donate_subscription(params[:plan_id].to_i, params[:charity_group_id].to_s, params[:id], current_donor.email, set_token.id)
            format.json { render json: donation }
          else
            format.json { head :not_found }
          end
        end
      end
    else
      render json: {:message => "Wrong parameters"}.to_json
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

  def show_token_info
    find_donation = Donation.find(params[:id].to_s)
    check_is_current_donor = current_donor.payment_accounts.find(find_donation.payment_account_id)
    if check_is_current_donor
      retrieve_token = retrieve_token_info(find_donation.stripe_token)
    else
      retrieve_token = {:message => "Cannot retrieve token information"}.to_json
    end
    respond_to do |format|
      format.json { render json: retrieve_token }
    end
  end

  def show_data_subscription
    find_donation = Donation.find(params[:id].to_s)
    check_is_current_donor = current_donor.payment_accounts.find(find_donation.payment_account_id)
    
    respond_to do |format|
      if check_is_current_donor
        retrieve_customer_data = retrieve_customer_data(find_donation.cust_id)
        format.json { render json: retrieve_customer_data }
      else
        format.json { head :not_found }
      end
    end
  end

  def cancel_donate_subscription
    find_donation = Donation.find(params[:id].to_s)
    check_is_current_donor = current_donor.payment_accounts.find(find_donation.payment_account_id)

    respond_to do |format|
      if check_is_current_donor
        cancel_subscription = cancel_subscription(find_donation.cust_id)
        format.json { render json: cancel_subscription }
      else
        format.json { head :not_found }
      end
    end   
  end

  protected

  def current_donor_id
    current_donor.payment_accounts.find(params[:id].to_s)
  end

end
