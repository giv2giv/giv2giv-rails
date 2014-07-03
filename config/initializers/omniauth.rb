OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, App.facebook['app_id'], App.facebook['app_secret']#, :scope => 'email,user_birthday,read_stream'
  provider :dwolla, App.dwolla['api_key'], App.dwolla['api_secret'], :scope => 'accountinfofull|send|request', :provider_ignores_state => true
end