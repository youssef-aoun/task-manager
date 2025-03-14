require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings.
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Cache assets for far-future expiry.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Store uploaded files on the local file system.
  config.active_storage.service = :local

  # Enforce SSL in production.
  config.assume_ssl = true
  config.force_ssl = true

  # Set log level (defaults to "info").
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent logs from being cluttered with health checks.
  config.silence_healthcheck_path = "/up"

  # Do not log deprecations.
  config.active_support.report_deprecations = false

  # Enable caching using the default memory store.
  config.cache_store = :memory_store

  # Configure ActiveJob to run synchronously (no external job queue needed).
  config.active_job.queue_adapter = :async

  # Set host for mailer links (if needed).
  config.action_mailer.default_url_options = { host: "example.com" }

  # Enable I18n fallbacks.
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end
