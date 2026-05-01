source "https://rubygems.org"

ruby "3.4.7"

gem "rails", "~> 7.1.6"

# Database
gem "pg", "~> 1.1"

# Web server
gem "puma", ">= 5.0"

# Background jobs
gem "sidekiq", "~> 7.3"
gem "sidekiq-cron", "~> 1.12"
gem "connection_pool", "~> 2.4"

# Redis client
gem "redis", "~> 5.3"

# Environment variables
gem "dotenv-rails"

gem "rack-cors"

# HTTP client (for external API calls)
gem "faraday", "~> 2.12"
gem "faraday-retry", "~> 2.2"

# Twilio SDK (WhatsApp messaging)
gem "twilio-ruby", "~> 7.5"

# JSON serialization
gem "oj", "~> 3.16"

# Pagination
gem "kaminari", "~> 1.2"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

gem 'money-rails'
gem 'i18n'

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "pry-rails"
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.4"
  gem "shoulda-matchers", "~> 6.2"
end

group :development do
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
end

group :test do
  gem "webmock", "~> 3.23"
  gem "vcr", "~> 6.3"
  gem "simplecov", require: false
end
