class Api::SessionsController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:create, :destroy, :omniauth_callback, :dwolla_start, :dwolla_finish]

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

  def dwolla_start
    Dwolla::api_key = App.dwolla['api_key']
    Dwolla::api_secret = App.dwolla['api_secret']
    
    authUrl = Dwolla::OAuth.get_auth_url("https://apitest.giv2giv.org/dwolla/finish?donor_token=fun")

    respond_to do |format|
      format.html { render json: { url: authUrl } }
    end
  end

  def dwolla_finish
    Dwolla::api_key = App.dwolla['api_key']
    Dwolla::api_secret = App.dwolla['api_secret']
   
    token = Dwolla::OAuth.get_token(params['code'], "https://apitest.giv2giv.org/dwolla/finish?donor_token=fun")

    Dwolla::token = token

    Rails.logger.debug Dwolla::Users.get


    # create external account, payment account, etc using dwolla info

  end


  def omniauth_callback

    auth = request.env["omniauth.auth"]

Rails.logger.debug(auth)

   Rail.logger.debug request.env["omniauth.params"]["donor_token"]

    donor_id = Session.find_by_token(request.env["omniauth.params"]["donor_token"]).donor_id

    if donor_id
      external_account = ExternalAccount.create_with_omniauth(auth, donor_id)
    end

    respond_to do |format|
        format.html { render json: external_account, status: :created }
    end
    
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
