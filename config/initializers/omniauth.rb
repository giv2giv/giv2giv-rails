OmniAuth.config.logger = Rails.logger
#OmniAuth.config.full_host = "https://apitest.giv2giv.org"

Rails.application.config.middleware.use OmniAuth::Builder do
	provider :facebook, App.facebook['app_id'], App.facebook['app_secret']#, :scope => 'email,user_birthday,read_stream'

  provider :dwolla, ENV['DWOLLA_KEY'], ENV['DWOLLA_SECRET'], :scope => 'accountinfofull|send|request', :provider_ignores_state => true
end