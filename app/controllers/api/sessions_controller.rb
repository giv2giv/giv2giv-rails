class Api::SessionsController < Api::BaseController

  skip_before_filter :require_authentication, :only => [:create, :create_facebook, :destroy, :omniauth_callback, :dwolla_start, :dwolla_finish]

  def create
    password_hash = secure_password(params[:password].to_s)
    donor = Donor.authenticate(params[:email].to_s, password_hash)

    respond_to do |format|
      if donor
        sess = Session.find_or_create_by_donor_id(donor.id)
        format.json { render json: sess, status: :created }
      else
        format.json { render :json => {:message => "unauthorized"}.to_json, :status => :unauthorized }
      end
    end
  end

  def create_facebook

    token = params[:token]

    graph = Koala::Facebook::API.new(token)
    profile = graph.get_object("me")

    if (profile["email"])
      donor = Donor.find_by_email(profile["email"])
    else
      respond_to do |format|
        format.json { render json: {:message => "unauthorized"}.to_json, status: :unauthorized }      
      end
    end

   # immediately get 60 day auth token
    oauth = Koala::Facebook::OAuth.new(App.facebook['app_id'], App.facebook['app_secret'])
    new_access_info = oauth.exchange_access_token_info token
    new_access_token = new_access_info["access_token"]
    new_access_expires_at = DateTime.now + new_access_info["expires"].to_i.seconds


    if !donor
      donor = Donor.new do |d|
        d.name = profile["name"]
        d.email = profile["email"]
        d.password = SecureRandom.urlsafe_base64
        d.type_donor = 'registered'
        d.accepted_terms = params["accepted_terms"]
        d.accepted_terms_on = DateTime.now
      end
      donor.save!
      Rails.logger.debug 'donor saved'
    end

    account = ExternalAccount.find_by_uid_and_provider(profile["id"], 'Facebook')

    if !account
      account = ExternalAccount.new do |a|
        a.donor_id = donor.id
        a.provider = 'Facebook'
        a.uid = profile["id"]
        a.name = profile["name"]
        a.oauth_token = new_access_token
        a.oauth_expires_at = new_access_expires_at
      end
      account.save!
    end

    sess = Session.find_or_create_by_donor_id(donor.id)

    respond_to do |format|
      if sess
        format.json { render json: sess, status: :created }
      else
        format.json { render json: {:message => "unauthorized"}.to_json, status: :unauthorized }      
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

    #Rail.logger.debug request.env["omniauth.params"]["donor_token"] #if parameter passed

    auth = request.env["omniauth.auth"]

    donor = Donor.find_by_email(auth["extra"]["raw_info"]["email"])

    if !donor
      donor = Donor.new do |d|
        d.name = auth["extra"]["raw_info"]["name"]
        d.email = auth["extra"]["raw_info"]["email"]
        d.password = SecureRandom.urlsafe_base64
        d.type_donor = 'registered'
        d.accepted_terms = true
        d.accepted_terms_on = DateTime.now
      end
      donor.save!
    end

    account = ExternalAccount.find_by_donor_id_and_provider(donor.id, auth["provider"])

    if !account
      account = ExternalAccount.new do |a|
        a.donor_id = donor.id
        a.provider = auth["provider"]
        a.uid = auth["uid"]
        a.name = auth["extra"]["raw_info"]["name"]
        a.oauth_token = auth["credentials"]["token"]
        a.oauth_expires_at = Time.at(auth["credentials"]["expires_at"])
      end
      account.save!
    end

    sess = Session.find_or_create_by_donor_id(donor.id)

    respond_to do |format|
      if sess
        format.html { render text: {session: sess.to_json, donor: donor.to_json}, status: :created }
      else
        format.html { render text: {:message => "unauthorized"}.to_json, status: :unauthorized }      
      end
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
