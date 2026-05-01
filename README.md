# BG Price Tracker

## Project Summary
BG Price Tracker is a WhatsApp bot for board game price workflows.

It currently focuses on user onboarding/consent and collection building, creating the foundation for future price tracking features (buy-low and sell-high alerts).

## Technologies Used

### Backend
- Ruby 3.4.7
- Rails 7.1 (API-first)
- Puma

### Data
- PostgreSQL
- Redis
- ActiveRecord
- money-rails

### Messaging and External Integrations
- Twilio WhatsApp API (`twilio-ruby`)
- Google Gemini API
- ngrok (local webhook tunneling)

### Background Processing
- Sidekiq
- sidekiq-cron

### API and Utilities
- Faraday
- faraday-retry
- rack-cors
- Oj

### Testing and Quality
- RSpec
- FactoryBot
- Shoulda Matchers
- WebMock
- SimpleCov
- RuboCop (Rails + RSpec)

### DevOps and Environment
- Docker
- Docker Compose
# bg-price-tracker
