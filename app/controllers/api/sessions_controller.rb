class Api::SessionsController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:create, :destroy, :omniauth_callback]

  def create
    password_hash = secure_password(params[:password].to_s)
    donor = Donor.authenticate(params[:email].to_s, password_hash)

    respond_to do |format|
      if donor
        sess = Session.find_or_create_by_donor_id(donor.id)
        format.json { render json: {session: sess, donor: donor}, status: :created }
      else
        format.json { render :json => {:message => "unauthorized"}.to_json, :status => :unauthorized }
      end
    end
  end

  def omniauth_callback

    auth = request.env["omniauth.auth"]

    # donor_id = request.env["omniauth.params"]["donor_id"] # if original /auth/facebook called with ?donor_id=1234
    # How do we secure this to prevent forgery?
    #ExternalAccount.find_by_provider_and_uid(auth["provider"], auth["uid"]) || ExternalAccount.create_with_omniauth(auth)
    
    donor_id = request.env["omniauth.params"]["donor_id"] # if original /auth/facebook called with ?donor_id=1234

    external_account = ExternalAccount.create_with_omniauth(auth, donor_id)

    respond_to do |format|
        format.html { render json: external_account, status: :created }
    end

      #end
    #end
    
  end

  def ping
    if current_session
      respond_to do |format|
        format.json { render json: {session: current_session}, status: :created }
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
