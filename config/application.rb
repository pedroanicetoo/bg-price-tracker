require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BgPriceTracker
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Time zone
    config.time_zone = "America/Sao_Paulo"
    config.active_record.default_timezone = :utc

    # Active Job backend
    config.active_job.queue_adapter = :sidekiq

    # Cache store backed by Redis
    config.cache_store = :redis_cache_store, {
      url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"),
      namespace: "bg_price_tracker:cache"
    }

    # Session store backed by Redis (used for onboarding flow state)
    config.session_store :cache_store,
      key: "_bg_price_tracker_session",
      expire_after: 30.minutes

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]
    config.i18n.default_locale = :'pt-BR'
    config.i18n.available_locales = [:en, :'pt-BR']
  end
end
