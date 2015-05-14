class Api::EndowmentController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:index, :show, :find_by_slug, :trending, :near, :anonymous_donation, :widget_data, :autocomplete]
  before_action :set_endowment, :only => [:widget_data]

  def index
    pagenum = params[:page] || 1
    perpage = params[:per_page] || 10

    #query = (params[:query] || "").tr(" ", "%")
    query = params[:query] || ""

    perpage=50 if perpage.to_i > 50

    endowments = []
    charities = []
    endowments_array = []

    #tags = Tag.find(:all, :conditions=> [ "name LIKE ?", "%#{query}%" ])
    #tags.each do |tag|
      #tag.charities.each do |c|
        #charities << c
      #end
    #end

    if query == ""
      if current_donor.present? && current_donor.id
        endowments = Endowment.page(pagenum).per(perpage).where("(visibility = ? OR donor_id = ?)", "public", current_donor.id).order("RAND()")
      else
        endowments = Endowment.page(pagenum).per(perpage).where("visibility = ?", "public").order("RAND()")
      end
    else
      if current_donor.present? && current_donor.id
        
        #endowments = Endowment.search query #, where: {visibility: "public" }#, or: [{donor_id: current_donor.id}] }

        endowments = Endowment.page(pagenum).per(perpage).where("name LIKE ? AND (visibility = ? OR donor_id = ?)", query, "public", current_donor.id).order("RAND()")
      else
        endowments = Endowment.page(pagenum).per(perpage).where("name LIKE ? AND visibility = ?", query, "public").order("RAND()")
      end
    end

    endowments.each do |endowment|

      if current_donor && current_donor.id
        my_balances = current_donor.my_balances(endowment.id)
      end

      endowment_hash = {
        "id" => endowment.id,
        "created_at" => endowment.created_at,
        "updated_at" => endowment.updated_at,
        "name" => endowment.name,
        "slug" => endowment.slug,
        "description" => endowment.description || "",
        "visibility" => endowment.visibility,
        "my_balances" => my_balances || "",
        "global_balances" => endowment.global_balances,
        "charities" => endowment.charities
      }
      endowments_array << endowment_hash
    end # endowment.each

    respond_to do |format|
      if endowments_array.present?
        format.json { render json: { :endowments => endowments_array }.to_json }
      else
        format.json { render json: { :message => "Not found" }.to_json }
      end
    end

  end

  def create
    respond_to do |format|

      endowment = Endowment.new(endowment_params)

      endowment.donor_id = current_session.donor_id
      if endowment.save
        if params.has_key?(:charities)
          charities = endowment.add_charity(params[:charities])
        end
        format.json { render json: {:endowment => endowment}.to_json(:include => charities), status: :created }
      else
        format.json { render json: endowment.errors , status: :unprocessable_entity }
      end
    end
  end


  def show
    #endowment = Endowment.find_by_id(params[:id])

    if current_donor.present? && current_donor.id
      endowment = Endowment.where("(id = ? OR slug = ?) AND (visibility = ? OR donor_id = ?)",params[:id], params[:id], "public", current_donor.id).last
      my_balances = current_donor.my_balances(endowment.id)
    else
      endowment = Endowment.where("(id = ? OR slug = ?) AND visibility = ?", params[:id], params[:id], "public").last
    end

    endowment_hash = {
      "id" => endowment.id,
      "created_at" => endowment.created_at,
      "updated_at" => endowment.updated_at,
      "name" => endowment.name,
      "slug" => endowment.slug,
      "description" => endowment.description || "",
      "visibility" => endowment.visibility,
      "my_balances" => my_balances || "",
      "global_balances" => endowment.global_balances,
      "charities" => endowment.charities
    }

    respond_to do |format|
      if endowment
        format.json { render json: { endowment: endowment_hash }.to_json }
      else
        format.json { head :not_found }
      end
    end
  end

  def anonymous_donation
    endowment = Endowment.find_by_id(params[:id])

    if endowment && params[:accepted_terms] && params[:stripeToken] && params[:amount]
      respond_to do |format|
        donation = endowment.anonymous_donation(params[:accepted_terms], params[:stripeToken], params[:endowment_id], params[:amount], params[:email])
        if donation
          format.json { render json: donation }
        else
          format.json { head :not_found }
        end
      end
    end
  end

  def rename_endowment
    endowment = Endowment.find_by_id(params[:id])
    if (endowment.donor_id.to_s.eql?(current_session.donor_id))
      respond_to do |format|
        if endowment.donations.size >= 1
          format.json { render json: "Cannot edit endowment when it already has donations to it" }
        else
          endowment.update_attributes(endowment_params)
          format.json { render json: { :message => "endowment has been updated", :endowment => params[:endowment] }.to_json }
        end
      end
    else
      render json: { :message => "You cannot edit this endowment" }.to_json
    end
  end

  def add_charity
    endowment = Endowment.find_by_id(params[:id])

    if (endowment.donor_id.to_s.eql?(current_session.donor_id))
      respond_to do |format|
        if endowment.donations.size < 1
          endowment.add_charity(params[:charities])
          format.json { render json: { :message => "Charity has been added"}.to_json }
        else
          format.json { render json: "Cannot edit endowment when it already has donations to it" }
        end
      end #respond_to
    else
      render json: { :message => "You cannot edit this endowment" }.to_json
    end
  end

  def remove_charity
    endowment = Endowment.find_by_id(params[:id])
    if (endowment.donor_id.to_s.eql?(current_session.donor_id))
      respond_to do |format|
        if endowment.donations.size < 1
          endowment.remove_charity(params[:id], params[:charity_id])
          format.json { render json: { :message => "Charity has been removed" }.to_json }
        else
          format.json { render json: "Cannot edit endowment when it already has donations to it" }
        end
      end #respond_to
    else
      render json: { :message => "You can edit this endowment" }.to_json
    end
  end

  def destroy
    endowment = Endowment.find_by_id(params[:id])
    if (endowment.donor_id.to_s.eql?(current_session.donor_id))
      respond_to do |format|
        if endowment.donations.size < 1
          endowment.delete(params[:charity])
          format.json { render json: "Destroyed #{params[:charity]} record." }
        else
          format.json { render json: "Cannot edit endowment when it already has donations to it" }
        end
      end
    else
      render json: { :message => "You can edit this endowment" }.to_json
    end
  end

  def find_by_slug
    endowment = Endowment.friendly.find(params[:slug])
    respond_to do |format|
      if endowment
        format.json { render json: endowment }
      else
        format.json { head :not_found }
      end
    end
  end

  def autocomplete
    render json: Endowment.search(params[:q], fields: [{name: :word_start}], limit: 30).map {|endowment| {value: endowment.name, id: endowment.id}}
  end

  def my_endowments
    endowments = current_donor.endowments

    endowments_array = []

    endowments.each do |endowment|
      my_balances = current_donor.my_balances(endowment.id) || ""
      endowment_hash = {
        "id" => endowment.id,
        "created_at" => endowment.created_at,
        "updated_at" => endowment.updated_at,
        "name" => endowment.name,
        "slug" => endowment.slug,
        "description" => endowment.description,
        "visibility" => endowment.visibility,
        "my_balances" => my_balances,
        "global_balances" => endowment.global_balances,
        "charities" => endowment.charities              
      }
      endowments_array << endowment_hash
    end # endowment.each

    respond_to do |format|
      if endowments_array.present?
        format.json { render json: { :endowments => endowments_array }.to_json }
      else
        format.json { render json: { :message => "Not found" }.to_json }
      end
    end
  end

  def trending
    donations = Donation.where('created_at >= ?', 1.month.ago)
    endowments = donations.group(:endowment_id).map do |donation|
      {
        'id' => donation.endowment_id,
        'name' => Endowment.find(donation.endowment_id).name,
        'since_date' => 1.month.ago.to_i,
        'donations' => Donation.where("created_at >= ? AND endowment_id = ?", 1.month.ago, donation.endowment_id).sum(:gross_amount) #TODO there must be a way to include sum in the mapped hash
      }
    end

    respond_to do |format|
      if endowments.present?
        format.json { render json: { :endowments => endowments.sort_by { |id, name, since_date, donations| donations }.reverse!.first(10) }.to_json }
      else
        format.json { render json: { :message => "Not found" }.to_json }
      end
    end
  end

  def near
    radius = (params[:radius] || 50).to_i
    endowments_hash = []

    if params.has_key?(:latitude) && params.has_key?(:longitude)
      charities = Charity.near([params[:latitude].to_f, params[:longitude].to_f], radius, :order => "distance").limit(50)
    else
      location_by_ip = request.location
      charities = Charity.near([location_by_ip.latitude, location_by_ip.longitude], radius, :order => "distance").limit(50)
    end

    if charities.present?
      charities.each do |charity|
        endowments_hash << charity.endowments
      end
    end
    
    respond_to do |format|
      if endowments_hash.present?
        format.json { render json: { :endowments => endowments_hash }.to_json }
      else
        format.json { head :not_found }
      end
    end
  end

  def widget_data
    render json: @endowment
  end


  private
    def endowment_params
      allow = [:name, :visibility, :description, :charity_id]
      params.require(:endowment).permit(allow)
    end
    def set_endowment
      @endowment = Endowment.where("(id = ? OR slug = ?) AND visibility = ?", params[:id], params[:id], "public").last
    end
    
end
