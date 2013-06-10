class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :require_user

private
  def require_user
    raise "be_user:" if !current_user
  end

  def current_user
    @current_user ||= session[:session_id] ? Session.find(session[:id]).donor : nil
  end




end
