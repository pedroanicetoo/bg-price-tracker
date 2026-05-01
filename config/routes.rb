require "sidekiq/web"

# API-only apps strip session/cookie middleware, but Sidekiq::Web requires both
# for CSRF protection. Inject them directly onto Sidekiq::Web so only that
# mounted route is affected — the rest of the API stack is unchanged.
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CacheStore,
  key:          "_sidekiq_session",
  expire_after: 1.hour

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  namespace :webhooks do
    post "whatsapp", to: "whatsapp#inbound"
  end

  namespace :api do
    namespace :v1 do
    end
  end
end
