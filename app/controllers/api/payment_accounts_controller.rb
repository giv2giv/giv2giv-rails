class Api::PaymentAccountsController < Api::BaseController

  def index
    pas = current_donor.payment_accounts

    respond_to do |format|
      format.json { render json: pas }
    end
  end

  def create
    if(params.has_key?(:number) && params.has_key?(:exp_month) && params.has_key?(:exp_year) && params.has_key?(:cvc) && params.has_key?(:payment_account))
      pa = PaymentAccount.new_payment(params)
      if pa.id.empty?
        render json: {:message => "Failed create payment account"}.to_json
      else
        payment = PaymentAccount.new({:donor => current_donor}.merge(params[:payment_account]))
        payment.token = pa.id
        respond_to do |format|
          if payment.save
            format.json { render json: payment, status: :created }
          else
            format.json { render json: payment.errors, status: :unprocessable_entity }
          end
        end
      end
    else
      render json: {:message => "Failed create payment account"}.to_json
    end
  end

  def update
    pa = current_donor.payment_accounts.find(params[:id].to_s)

    respond_to do |format|
      if pa && pa.update_attributes(params[:payment_account])
        format.json { render json: pa }
      elsif pa
        format.json { render json: pa.errors, status: :unprocessable_entity }
      else
        format.json { head :not_found }
      end
    end
  end

  def show
    pa = current_donor.payment_accounts.find(params[:id].to_s)

    respond_to do |format|
      if pa
        format.json { render json: pa }
      else
        format.json { head :not_found }
      end
    end
  end

  def destroy
    pa = current_donor.payment_accounts.find(params[:id].to_s)

    respond_to do |format|
      if pa
        pa.destroy
        format.json { render json: pa }
      else
        format.json { head :not_found }
      end
    end
  end

  def donate
    pa = current_donor.payment_accounts.find(params[:id].to_s)

    respond_to do |format|
      if pa && donation = pa.donate(params[:amount].to_i, params[:charity_group_id].to_s, params[:id])
        format.json { render json: donation }
      else
        format.json { head :not_found }
      end
    end
  end

end
