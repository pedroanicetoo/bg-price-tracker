# spec/support/webmock.rb
require 'webmock/rspec'

# Block all real HTTP requests in test environment.
# Use VCR cassettes for recorded HTTP interactions (scrapers, Meta API).
WebMock.disable_net_connect!(allow_localhost: true)
