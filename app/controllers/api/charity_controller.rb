class Api::CharityController < Api::BaseController

  skip_before_filter :require_authentication

  def index
    page = params[:page] || 1
    per_page = [params[:per_page], 30].compact.min # limit to 30 results per page
    results = Charity.all.paginate(:per_page => per_page, :page => page)

    respond_to do |format|
      format.json { render json: results }
    end
  end

  def show
    charity = Charity.find(params[:id].to_s)

    respond_to do |format|
      if charity
        format.json { render json: charity }
      else
        format.json { head :not_found }
      end
    end
  end

  def search

  end

end
