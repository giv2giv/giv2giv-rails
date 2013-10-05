class Api::BalancesController < Api::BaseController
  before_filter :require_authentication

  def show_grants

    if params.has_key?(:start_date) and params.has_key?(:end_date)
      grants = Grant.where("created_at >= '#{params[:start_date]}' AND created_at <= '#{params[:end_date]}'")
    else
      grants = Grant.all
    end

    respond_to do |format|
      format.json { render json: grants }
    end
  end

end