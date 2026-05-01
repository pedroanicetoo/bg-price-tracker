# config/initializers/sidekiq.rb

require "sidekiq/web"

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  # Load cron schedule when Sidekiq server boots
  schedule_file = Rails.root.join("config/schedule.yml")
  if File.exist?(schedule_file)
    schedule = YAML.load_file(schedule_file, aliases: true) || {}
    SidekiqCron::Job.load_from_hash(schedule) unless schedule.empty?
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

# Protect the Sidekiq web UI with HTTP Basic Auth in production.
# SIDEKIQ_WEB_PASSWORD must be explicitly set — no empty-string fallback.
if Rails.env.production?
  Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
    ActiveSupport::SecurityUtils.secure_compare(
      user, ENV.fetch("SIDEKIQ_WEB_USERNAME", "admin")
    ) &
      ActiveSupport::SecurityUtils.secure_compare(
        password, ENV.fetch("SIDEKIQ_WEB_PASSWORD")
      )
  end
end
