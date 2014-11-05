class Api::CharityController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:index, :show, :find_by_slug, :show_endowments, :near]

  def index
    pagenum = params[:page] || 1
    perpage = params[:per_page] || 10
    perpage = 50 if perpage.to_i > 50
#    offset_count = (page.to_i-1)*perpage.to_i

    query = params[:query] || ""
    city = params[:city]

    charities_with_matching_tags = []
    charities_with_matching_name = []
    charity_list = []

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

    charities_with_matching_name.page(pagenum).per(perpage).each do |charity|

      #if current_donor && current_donor.id
        #my_balances = current_donor.my_balances(endowment.id)
      #end
      charity_hash = {
      "id" => charity.id,
      "created_at" => charity.created_at,
      "updated_at" => charity.updated_at,
      "ein" => charity.ein,
      "name" => charity.name.titleize,
      "address" => charity.address,
      "city" => charity.city.titleize,
      "state" => charity.state,
      "zip" => charity.zip,
      "tax_period" => charity.group_code,
      "asset_amount" => charity.group_code,
      "income_amount" => charity.group_code,
      "revenue_amount" => charity.revenue_amount,
      "slug" => charity.slug,
      "tags" => charity.tags.pluck(:name),
      "donor_count" => charity.donor_count,
      "current_balance" => charity.current_balance,
      "pending_grants" => charity.pending_grants,
      "delivered_grants" => charity.delivered_grants
    }
      charity_list << charity_hash
    end # charity.each

    respond_to do |format|
      if charity_list.present?
        format.json { render json: { :charities => charity_list } }
      else
        format.json { render json: { :message => "Not found" }.to_json }
      end
    end

  end

  def show
    charity = Charity.where("(id=? OR slug=?)", params[:id], params[:id]).last

    charity_hash = {
      "id" => charity.id,
      "created_at" => charity.created_at,
      "updated_at" => charity.updated_at,
      "ein" => charity.ein,
      "name" => charity.name.titleize,
      "address" => charity.address,
      "city" => charity.city.titleize,
      "state" => charity.state,
      "zip" => charity.zip,
      "tax_period" => charity.group_code,
      "asset_amount" => charity.group_code,
      "income_amount" => charity.group_code,
      "revenue_amount" => charity.revenue_amount,
      "slug" => charity.slug,
      "tags" => charity.tags.pluck(:name),
      "donor_count" => charity.donor_count,
      "current_balance" => charity.current_balance,
      "pending_grants" => charity.pending_grants,
      "delivered_grants" => charity.delivered_grants
    }


    respond_to do |format|
      if charity
        format.json { render json: { :charity => charity_hash } }
      else
        format.json { head :not_found }
      end
    end
  end
  
  def find_by_slug
    charity = Charity.friendly.find(params[:slug])
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
    radius = (params[:radius] || 25).to_i
    charity_list=[]

    if radius > 100
      radius = 100
    end

    if params.has_key?(:latitude) && params.has_key?(:longitude)
      charities = Charity.near([params[:latitude].to_f, params[:longitude].to_f], radius)
    else
      location_by_ip = request.location
      charities = Charity.near([location_by_ip.latitude, location_by_ip.longitude], radius)
    end

    charities.each do |charity|

      charity_hash = {
        "id" => charity.id,
        "created_at" => charity.created_at,
        "updated_at" => charity.updated_at,
        "ein" => charity.ein,
        "name" => charity.name.titleize,
        "address" => charity.address,
        "city" => charity.city.titleize,
        "state" => charity.state,
        "zip" => charity.zip,
        "tax_period" => charity.group_code,
        "asset_amount" => charity.group_code,
        "income_amount" => charity.group_code,
        "revenue_amount" => charity.revenue_amount,
        "slug" => charity.slug,
        "tags" => charity.tags.pluck(:name),
        "donor_count" => charity.donor_count,
        "current_balance" => charity.current_balance,
        "pending_grants" => charity.pending_grants,
        "delivered_grants" => charity.delivered_grants
      }
      charity_list << charity_hash
    end # charity.each

    respond_to do |format|
      if charity_list.present?
        format.json { render json: { :charities => charity_list } }
      else
        format.json { render json: { :message => "Not found" }.to_json }
      end
    end
  end

end

