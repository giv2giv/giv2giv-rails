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
    ss = params[:search_string]
    # FIXME sanitize_input !

    charity_groups = []

    tags = Tag.all("name: \"#{ss}\"", :type => :fulltext)
    tags.each do |tag|
      tag.charities.each do |c|
        charities << c
      end
    end

    charities.each do |c|
      charity_groups << c.charity_groups
    end

    CharityGroup.all("name: \"#{ss}\"", :type => :fulltext).each do |cg|
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

    respond_to do |format|
      if !group.donations.first
        format.json { render json: "Cannot edit Charity Group when it already has donations to it" }
      else
        group.update_attribute( :name => params[:new_name] )
      end
    end #respond_to

  end #update

  def add_charity
    group = CharityGroup.find(params[:id].to_s)

    respond_to do |format|
      if group.donations.first
        group.add(params[:charity_id])
      else
        format.json { render json: "Cannot edit Charity Group when it already has donations to it" }
      end
    end #respond_to

  end



  def destroy
    group = CharityGroup.find(params[:id].to_s)

    respond_to do |format|
      if group.donations.first
        group.delete(params[:charity])
        format.json { render json: "Destroyed #{params[:charity]} record." }
      else
        format.json { redner json: "Cannot edit Charity Group when it already has donations to it" }
      end #if
    end #respond_)to
  end #destroy 


end
