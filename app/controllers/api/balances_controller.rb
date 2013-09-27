class Api::BalancesController < Api::BaseController
  include EtradeHelper
  before_filter :require_authentication

  def get_pin_etrade
  	auth = get_auth
  	render json: {:url => auth}.to_json
  end

  def pin_etrade
  	pin = enter_verifier(params[:pin])
  	respond_to do |format|
      format.json { render json: pin }
    end
  end

  def show_balances
  	stripe_balance = Stripe::Balance.retrieve
    etrade_balance = 0
    calc = (stripe_balance["pending"][0][:amount].to_f + 0) / 100
    render json: {:balance => calc.to_f, :currency => stripe_balance["pending"][0][:currency]}.to_json
  end

end