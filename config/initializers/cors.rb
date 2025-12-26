# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In production, replace with your actual frontend domain(s)
    # In development, we'll use specific localhost origins to allow credentials
    development_origins = [
      "http://localhost:3000",
      "http://localhost:3001",
      "http://localhost:5173", # Vite default
      "http://127.0.0.1:3000",
      "http://127.0.0.1:3001",
      "http://127.0.0.1:5173"
    ]

    # Add auto-detected IP from en0 interface for mobile testing
    if Rails.env.development?
      network_host = ENV.fetch("NETWORK_HOST", begin
        # Try to get the IP address from en0 interface
        ip_output = `ifconfig en0 | grep 'inet ' | awk '{print $2}'`.strip
        ip_output.empty? ? nil : "#{ip_output}"
      rescue => e
        Rails.logger.warn "cors: Failed to detect IP address: #{e.message}."
        nil
      end)
      if network_host.present?
        development_origins += [
        "http://#{network_host}:3000",
        "http://#{network_host}:3001",
        "http://#{network_host}:5173"
      ]
      end
    end

    origins Rails.env.production? ? [
      # Add your production domains here
      # "https://yourdomain.com"
    ] : development_origins

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [ :Authorization ],
      credentials: true # Allow cookies to be sent with cross-origin requests
  end
end
