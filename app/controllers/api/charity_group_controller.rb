class Api::CharityGroupController < Api::BaseController

  def index
    page = params[:page] || 1
    per_page = [params[:per_page], 30].compact.min # limit to 30 results per page
    results = CharityGroup.all.paginate(:per_page => per_page, :page => page)

    respond_to do |format|
      format.json { render json: results }
    end
  end

  def create
    group = CharityGroup.new_with_charities(params[:charity_group])

    respond_to do |format|
      if group.save
        format.json { render json: group, status: :created }
      else
        format.json { render json: group.errors , status: :unprocessable_entity }
      end
    end
  end

  def show
    group = CharityGroup.find(params[:id].to_s)

    respond_to do |format|
      if group
        format.json { render json: group }
      else
        format.json { head :not_found }
      end
    end
  end

end
