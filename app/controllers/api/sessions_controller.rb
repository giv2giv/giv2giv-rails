class Api::SessionsController < Api::BaseController

  skip_before_filter :require_user, :only => [:create,
                                              :destroy]

  def create
    validate_params([:email, :password])
    user = Donor.authenticate(params[:email].to_s, params[:password].to_s)

    if user
      session[:session_id] = Session.create(:donor => user).id
      message="Successfully created session"
    else
      message="Session creation failed"
    end

    respond_to do |format|
      format.html { render :text => message }
      format.json { render :json => message }
    end
  end

  def destroy
    session[:session_id] = nil
    message = "Session destroyed"

    respond_to do |format|
      format.html { render :text => message }
      format.json { render :json => message }
    end
  end

end
