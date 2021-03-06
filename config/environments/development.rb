Radd::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  $stdout.sync = true

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Prevent email being sent in development
  # The messages are stored in tmp/letter_opener
  # config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.delivery_method = :smtp
  
  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true
  # config.action_mailer.default_url_options = { host: "localhost:3000",
  #     server: "54.227.248.152" }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true
  # When a new user registered with GovDash, a confirmation email is
  # sent. A user has this time window to confirm, he/she owns the email
  config.new_user_confirmation_expires_in = 72  # hours
  # Rails.configuration.new_user_confirmation_expires_in
end
