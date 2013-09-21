class Api::CharityGroupController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:index,
                                                        :show]

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
    group.donor_id = current_session.session_id
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

  def search
    ss = params[:keyword]
    
    charity_groups = []
    charities = []
    tags = Tag.find(:all, :conditions=> [ "name LIKE ?", "%#{params[:keyword]}%" ])
    tags.each do |tag|
      tag.charities.each do |c|
        charities << c
      end
    end

    charities.each do |c|
      charity_groups << c.charity_groups
    end

    CharityGroup.find(:all, :conditions=> [ "name LIKE ?", "%#{params[:keyword]}%" ]).each do |cg|
      charity_groups << cg
    end
    
    charity_groups = charity_groups.compact.flatten.uniq
    respond_to do |format|
      if !charity_groups.empty?
        format.json { render json: charity_groups }
      else
        format.json { head :not_found }
      end
    end
  end #search

  def rename_charity_group
    group = CharityGroup.find(params[:id].to_s)
    if (group.donor_id.to_s.eql?(current_session.session_id))
      respond_to do |format|
        if group.donations.size >= 1
          format.json { render json: "Cannot edit Charity Group when it already has donations to it" }
        else
          group.update_attributes(params[:charity_group])
          format.json { render json: {:message => "Charity Group has been updated", :charity_group => params[:charity_group]}.to_json }
        end
      end
    else
      render json: {:message => "You cannot edit this charity group"}.to_json
    end
  end

  def add_charity
    group = CharityGroup.find(params[:id].to_s)
    if (group.donor_id.to_s.eql?(current_session.session_id))
      respond_to do |format|
        if group.donations.size < 1 
          group.add_charity(params[:charity_id])
          format.json { render json: {:message => "Charity has been added"}.to_json }
        else
          format.json { render json: "Cannot edit Charity Group when it already has donations to it" }
        end
      end #respond_to
    else
      render json: {:message => "You cannot edit this charity group"}.to_json
    end
  end

  def remove_charity
    group = CharityGroup.find(params[:id].to_s)
    if (group.donor_id.to_s.eql?(current_session.session_id))
      respond_to do |format|
        if group.donations.size < 1 
          group.remove_charity(params[:id], params[:charity_id])
          format.json { render json: {:message => "Charity has been removed"}.to_json }
        else
          format.json { render json: "Cannot edit Charity Group when it already has donations to it" }
        end
      end #respond_to
    else
      render json: {:message => "You can edit this charity group"}.to_json
    end
  end

  def destroy
    group = CharityGroup.find(params[:id].to_s)
    if (group.donor_id.to_s.eql?(current_session.session_id))
      respond_to do |format|
        if group.donations.size < 1
          group.delete(params[:charity])
          format.json { render json: "Destroyed #{params[:charity]} record." }
        else
          format.json { render json: "Cannot edit Charity Group when it already has donations to it" }
        end
      end
    else
      render json: {:message => "You can edit this charity group"}.to_json
    end
  end 


end
