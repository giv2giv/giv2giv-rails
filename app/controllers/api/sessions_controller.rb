class Api::SessionsController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:create,
                                                        :destroy]

  def create
    password_hash = secure_password(params[:password].to_s)
    donor = Donor.authenticate(params[:email].to_s, password_hash)
    
    respond_to do |format|
      if donor
        sess = Session.find_or_create_by_session_id(donor.id)
        format.json { render json: sess, status: :created }
      else
        format.json { render :json => {:message => "unauthorized"}.to_json, :status => :unauthorized }
      end
    end
  end

  def destroy
    if current_session
      current_session.destroy 
      notice = "Successfuly remove your session"
    else
      notice = "You currently don't have any session active"
    end
    respond_to do |format|
      format.json { render :json => {:message => notice}.to_json }
    end
  end

end
