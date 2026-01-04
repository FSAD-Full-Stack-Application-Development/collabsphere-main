# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # TEMPORARY: allow all origins while troubleshooting CORS in deployment.
    # IMPORTANT: Using '*' with `credentials: true` is invalid per CORS spec,
    # so credentials are disabled here. Revert to a restrictive list of
    # allowed origins and enable credentials only when ready for production.
    origins '*'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false
  end
end
