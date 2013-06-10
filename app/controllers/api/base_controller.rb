class Api::BaseController < ApplicationController

  before_filter :force_ssl, :require_user

private

  def validate_params(required_params)
    required_params.each {|p| raise ArgumentError if !params.has_key?(p)}
  end

  def force_ssl
    render :text => "Go secure" if App.force_ssl && Rails.env.production? && !request.ssl?
  end

  def require_user
    raise AuthenticationRequired if !current_user
  end

  def current_user
    @current_user ||= session[:session_id] ? Session.find(session[:id]).donor : nil
  end

end
