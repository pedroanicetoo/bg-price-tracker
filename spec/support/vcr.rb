# spec/support/vcr.rb
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Scrub sensitive data from cassettes
  config.filter_sensitive_data('<WHATSAPP_API_TOKEN>') { ENV['WHATSAPP_API_TOKEN'] }
  config.filter_sensitive_data('<DB_PASSWORD>')        { ENV['DB_PASSWORD'] }
  config.filter_sensitive_data('<GEMINI_API_KEY>')     { ENV['GEMINI_API_KEY'] }

  config.default_cassette_options = {
    record: :new_episodes,
    re_record_interval: 7.days
  }
end
