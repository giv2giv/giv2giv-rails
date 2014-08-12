OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, App.facebook['app_id'], App.facebook['app_secret'], :scope => 'public_profile,email,user_friends'
  provider :google_oauth2, App.google['client_id'], App.google['client_secret'], {client_options: {ssl: {ca_file: Rails.root.join("cacert.pem").to_s}}}
  provider :dwolla, App.dwolla['api_key'], App.dwolla['api_secret'], :scope => 'accountinfofull|send|request', :provider_ignores_state => true
end