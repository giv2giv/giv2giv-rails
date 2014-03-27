OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
	provider :developer #unless Rails.env.production?
  provider :facebook, App.facebook['app_id'], App.facebook['app_secret']
 #provider :dwolla, ENV['DWOLLA_KEY'], ENV['DWOLLA_SECRET'], :scope => 'accountinfofull|send|request', :provider_ignores_state => true

end