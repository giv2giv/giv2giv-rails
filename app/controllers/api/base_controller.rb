class Api::BaseController < ApplicationController
  require 'bcrypt'
  include BCrypt

  rescue_from Exception, :with => :render_exception
  force_ssl if App.force_ssl && Rails.env.production?

  before_filter :require_authentication

private

  def render_exception(exception)
    respond_to do |format|
      format.json { render json: { :message => exception.to_s }, status: :bad_request }
    end
  end

  def require_authentication
    authenticate_or_request_with_http_token do |token, options|
      @session = Session.find_by_token(token)
    end
  end

  def current_session
    # we should have session already except in sessions/destroy case
    return @session if @session

    token, options = ActionController::HttpAuthentication::Token.token_and_options(request)
    @session = token ? Session.find_by_token(token) : nil
  end

  def current_donor
    @current_donor ||= current_session ? current_session.donor : nil
  end

  def secure_password(password)
    return nil if password.blank?
    BCrypt::Password.create(password)
  end

end
