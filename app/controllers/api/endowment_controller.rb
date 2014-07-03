class Api::EndowmentController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:index, :show, :find_by_slug]

  def index
    pagenum = params[:page] || 1
    perpage = params[:per_page] || 10
    query = params[:query] || ""

    perpage=50 if perpage.to_i > 50

    endowments = []
    charities = []
    endowments_list = []

    #tags = Tag.find(:all, :conditions=> [ "name LIKE ?", "%#{query}%" ])
    #tags.each do |tag|
      #tag.charities.each do |c|
        #charities << c
      #end
    #end

    #charities.each do |c|
      #endowments << c.endowments
    #end
   
    q = "%#{query}%"
    if q=="%%"
      if current_donor.present? && current_donor.id
  	    endowments = Endowment.where("(visibility = ? OR donor_id = ?)", "public", current_donor.id).order("RAND()").limit(perpage)
      else
        endowments = Endowment.where("visibility = ?", "public").order("RAND()").limit(perpage)
      end
    else
      if current_donor.present? && current_donor.id
        endowments = Endowment.where("name LIKE ? AND (visibility = ? OR donor_id = ?)", q, "public", current_donor.id).order("RAND()").limit(perpage)
      else
        endowments = Endowment.where("name LIKE ? AND visibility = ?", q, "public").order("RAND()").limit(perpage)
      end
    end

#    endowments = endowments.page(pagenum).per(perpage)
#    endowments = endowments.compact.flatten.uniq.paginate(:page => page, :per_page => perpage)

    endowments.each do |endowment|
      
      if current_donor && current_donor.id
        my_balances = current_donor.my_balances(endowment.id)
      end
      
      endowment_hash = {
        "id" => endowment.id,
        "created_at" => endowment.created_at,
        "updated_at" => endowment.updated_at,
        "name" => endowment.name,
        "description" => endowment.description,
        "visibility" => endowment.visibility,
        "minimum_donation_amount" => endowment.minimum_donation_amount,
        "my_balances" => my_balances || "",
        "global_balances" => endowment.global_balances,
        "charities" => endowment.charities              
      }
      endowments_list << endowment_hash
    end # endowment.each

    respond_to do |format|
      if endowments_list.present?
        format.json { render json: { :endowments => endowments_list } }
      else
        format.json { render json: { :message => "Not found" }.to_json }
      end
    end

  end

  def create
    #params[:endowment] = { name: params[:name], minimum_donation_amount: params[:minimum_donation_amount], visibility: params[:visibility], description: params[:description] }

    respond_to do |format|

      if params[:minimum_donation_amount].to_f < 2.0
        format.json { render json: { :message => "Minimum donation at giv2giv is $2" }.to_json }
      end

      endowment = Endowment.new(params[:endowment])

      endowment.donor_id = current_session.donor_id
      if endowment.save
        if params.has_key?(:charities)
          charities = endowment.add_charity(params[:charities])
        end
        format.json { render json: endowment.to_json(:include => charities)}
      else
        format.json { render json: endowment.errors , status: :unprocessable_entity }
      end
    end
  end


  def show
    endowment = Endowment.find_by_id(params[:id])

    if current_donor && current_donor.id
      my_balances = current_donor.my_balances(endowment.id)
    end

    endowment_hash = {
      "id" => endowment.id,
      "created_at" => endowment.created_at,
      "updated_at" => endowment.updated_at,
      "name" => endowment.name,
      "description" => endowment.description,
      "visibility" => endowment.visibility,
      "minimum_donation_amount" => endowment.minimum_donation_amount,
      "my_balances" => my_balances || "",
      "global_balances" => endowment.global_balances,
      "charities" => endowment.charities
    }

    respond_to do |format|
      if endowment
        format.json { render json: { endowment: endowment_hash } }
      else
        format.json { head :not_found }
      end
    end
  end

  def find_by_slug

    endowment_slug = params[:slug]

    if endowment_slug == ""
      render json: { :message => "Missing parameter slug" }
    else
      if current_donor.present? && current_donor.id
        endowment = Endowment.where("slug = ? AND (visibility = ? OR donor_id = ?)", endowment_slug, "public", current_donor.id).last
      else
        endowment = Endowment.where("slug = ? AND visibility = ?", endowment_slug, "public").last
      end
    end

    respond_to do |format|
      if endowment
        format.json { render json: endowment }
      else
        format.json { head :not_found }
      end
    end

  end

  def anonymous_donation
    endowment = Endowment.find_by_id(params[:id])
    if endowment && params[:accepted_terms] && params[:stripeToken] && params[:amount]
      respond_to do |format|
        if donation = endowment.anonymous_donation(params[:accepted_terms], params[:stripeToken], params[:endowment_id], params[:amount])
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
          endowment.update_attributes(params[:endowment])
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

  def my_endowments
    endowments = current_donor.endowments

    endowments_list = []

    endowments.each do |endowment|
      my_balances = current_donor.my_balances(endowment.id) || ""
      endowment_hash = {
        "id" => endowment.id,
        "created_at" => endowment.created_at,
        "updated_at" => endowment.updated_at,
        "name" => endowment.name,
        "description" => endowment.description,
        "visibility" => endowment.visibility,
        "minimum_donation_amount" => endowment.minimum_donation_amount,
        "my_balances" => my_balances,
        "global_balances" => endowment.global_balances,
        "charities" => endowment.charities              
      }
      endowments_list << endowment_hash
    end # endowment.each

    respond_to do |format|
      if endowments_list.present?
        format.json { render json: { :endowments => endowments_list } }
      else
        format.json { render json: { :message => "Not found" }.to_json }
      end
    end
  end

end
