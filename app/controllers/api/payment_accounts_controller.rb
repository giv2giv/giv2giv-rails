class Api::PaymentAccountsController < Api::BaseController

  def index
    pas = current_donor.payment_accounts

    respond_to do |format|
      format.json { render json: pas }
    end
  end

  def create
    pa = PaymentAccount.new({:donor => current_donor}.merge(params[:payment_account]))

    respond_to do |format|
      if pa.save
        format.json { render json: pa, status: :created }
      else
        format.json { render json: pa.errors , status: :unprocessable_entity }
      end
    end
  end

  def update
    pa = current_donor.payment_accounts.find(params[:id].to_s)

    respond_to do |format|
      if pa && pa.update_attributes(params[:payment_account])
        format.json { render json: pa }
      elsif pa
        format.json { render json: pa.errors , status: :unprocessable_entity }
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
      if pa && donation = pa.donate(params[:payment_account][:amount].to_s, params[:payment_account][:charity_group_id].to_s)
        format.json { render json: donation }
      else
        format.json { head :not_found }
      end
    end
  end

end
