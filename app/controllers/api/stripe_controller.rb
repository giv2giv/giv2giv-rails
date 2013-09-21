class Api::StripeController < Api::BaseController
  include StripeHelper
  before_filter :require_authentication

  def show_stripe_plan
    retrieve_plan = retrieve_stripe_plan
    respond_to do |format|
      format.json { render json: retrieve_plan }
    end
  end

end