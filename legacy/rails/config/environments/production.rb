require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.hosts = [ ENV.fetch("APP_HOST", "localhost") ]
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  config.action_cable.mount_path = "/cable"
  config.action_controller.perform_caching = true
  config.assume_ssl = ENV.fetch("ASSUME_SSL", "false") == "true"
  config.force_ssl = true
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "localhost"), protocol: "https" }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: ENV.fetch("SMTP_PORT", "587").to_i,
    domain: ENV.fetch("APP_HOST", "localhost"),
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain"),
    enable_starttls: true,
    open_timeout: 10,
    read_timeout: 10
  }
  config.active_job.queue_adapter = :inline
  config.active_record.attributes_for_inspect = [ :id ]
  config.active_record.dump_schema_after_migration = false
  config.active_storage.service = :local
  config.active_support.report_deprecations = false
  config.cache_store = :memory_store
  config.consider_all_requests_local = false
  config.eager_load = true
  config.enable_reloading = false
  config.i18n.fallbacks = true
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  config.silence_healthcheck_path = "/up"
end
