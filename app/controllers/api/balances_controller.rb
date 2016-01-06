class Api::BalancesController < Api::BaseController
  
  skip_before_filter :require_authentication, :only => [:show_grants]

  def show_grants

    grants = Grant.where("status = ?",'pending_approval')

    show_grants = grants.group(:charity_id).map do |grant|
      {
        'charity_id' => grant.charity_id,
        'charity_name' => grant.charity.name,
        'charity_email' => grant.charity.email,
        'grant_amount' => grants.where("charity_id = ?", grant.charity_id).sum(:grant_amount) #TODO there must be a way to include sum in the mapped hash
      }
    end
    show_grants = show_grants.sort_by { |hash| hash['name'].to_i }

    respond_to do |format|
      format.json { render json: show_grants }
    end
  end

  def deny_grant

    charity_id = params[:id]

    if charity_id && params[:password] == App.giv['giv_grant_password']
      denied_grants = Grant.where("status = ? AND charity_id = ?", "pending_approval", charity_id)
      denied_grants.each do |deny_grant|
        deny_grant.update_attributes(:status => 'denied')
      end
      message = 'Successfully denied charity'
    else
      message = 'Authorization denied'
    end

    respond_to do |format|
      format.json { render json: {:message => message}.to_json }
    end

  end

end
