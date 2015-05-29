Giv2givRails::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true
  #config.log_level = :warn

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.action_mailer.default_url_options = { :host => App.mailer["domain"] }
  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = false
  
  # Configured for mandrillapp.com
  config.action_mailer.smtp_settings = {
    :address   => App.mailer["address"],
    :port      => App.mailer["port"], # ports 587 and 2525 are also supported with STARTTLS
    :enable_starttls_auto => App.mailer["port"], # detects and uses STARTTLS
    :user_name => App.mailer["user_name"],
    :password  => App.mailer["password"], # SMTP password is any valid API key
    :authentication => App.mailer["authentication"], # Mandrill supports 'plain' or 'login'
    :domain => App.mailer["domain"] # your domain to identify your server when connecting
  }
end
