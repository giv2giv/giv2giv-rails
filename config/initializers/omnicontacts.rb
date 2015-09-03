require "omnicontacts"

Rails.application.middleware.use OmniContacts::Builder do
  importer :gmail, App.google['client_id'], App.google['client_secret']#, {:redirect_path => "/oauth2callback", :ssl_ca_file => "/etc/ssl/certs/curl-ca-bundle.crt"}
  #importer :yahoo, "consumer_id", "consumer_secret", {:callback_path => '/callback'}
  #importer :linkedin, "consumer_id", "consumer_secret", {:redirect_path => "/oauth2callback", :state => '<long_unique_string_value>'}
  #importer :hotmail, "client_id", "client_secret"
  importer :facebook, App.facebook['app_id'], App.facebook['app_secret']
end