# config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In production, restrict to known origins (e.g., admin dashboard domain).
    # Set ALLOWED_ORIGINS as a comma-separated list in .env
    origins ENV.fetch("ALLOWED_ORIGINS", "localhost:3000").split(",")

    resource "*",
      headers: :any,
      methods: %i[get post options],
      expose: ["Authorization"]
  end
end
