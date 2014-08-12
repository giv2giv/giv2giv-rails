Giv2givRails::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  #config.cache_classes = true

  config.log_level = :debug 

  # Configure static asset server for tests with Cache-Control for performance
  #config.serve_static_assets = true
  #config.static_cache_control = "public, max-age=3600"

  # Log error messages when you accidentally call methods on nil
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  config.action_mailer.smtp_settings = {
    :address   => App.mailer["address"],
    :port      => App.mailer["port"], # ports 587 and 2525 are also supported with STARTTLS
    :enable_starttls_auto => App.mailer["port"], # detects and uses STARTTLS
    :user_name => App.mailer["user_name"],
    :password  => App.mailer["password"], # SMTP password is any valid API key
    :authentication => App.mailer["authentication"], # Mandrill supports 'plain' or 'login'
    :domain => App.mailer["domain"], # your domain to identify your server when connecting
  }

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr
end
