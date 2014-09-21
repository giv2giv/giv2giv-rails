class Api::CharityController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:index, :show, :show_endowments, :near]

  def index
    pagenum = params[:page] || 1
    perpage = params[:per_page] || 10
    perpage = 50 if perpage.to_i > 50
#    offset_count = (page.to_i-1)*perpage.to_i

    query = params[:query] || ""
    city = params[:city]

    charities_with_matching_tags = []
    charities_with_matching_name = []

    #let's not sqli ourselves in the API
    nameq = "%#{query}%"
    cityq = "%#{city}%"
    #q = q.gsub!(' ','%')
    
    if cityq == "%%"
      charities_with_matching_name = Charity.where("name LIKE ? AND active = 'true'", nameq)
    else
      charities_with_matching_name = Charity.where("name LIKE ? AND city LIKE ? AND active='true'", nameq, cityq)
    end


    #tag_limit = perpage - charities_with_matching_name.size
    #Tag.where("name LIKE ?", q).each do |t|
    #    next if charities_with_matching_tags.size > tag_limit
    #    charities_with_matching_tags << t.charities
    #end

#    charities = charities_with_matching_name + charities_with_matching_tags
#    results = charities.compact.uniq.paginate(:page => page, :per_page => perpage, :total_entries => charities.count)
    results = charities_with_matching_name.page(pagenum).per(perpage)

    respond_to do |format|
      if !results.empty?
        format.json { render json: results.to_json(:include => [:tags => { :only => :name }] ) }
      else
        format.json { render json: {:message => "Not found"}.to_json }
      end
    end
  end

  def show
    charity = Charity.find(params[:id])
    # Return charity.tags in response body
    respond_to do |format|
      if charity
        format.json { render json: charity }
      else
        format.json { head :not_found }
      end
    end
  end

  def show_endowments
    charity = Charity.find(params[:id])
    respond_to do |format|
      if charity
        format.json { render json: charity.endowments}
      else
        format.json { head :not_found }
      end
    end
  end

  def near
    location_by_ip = request.location
    radius = params[:radius] || 25
    respond_to do |format|
      if location_by_ip
        format.json { render json: Charity.near(location_by_ip, radius)}
      else
        format.json { head :not_found }
      end
    end
  end

end

