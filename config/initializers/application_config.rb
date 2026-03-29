# frozen_string_literal: true

# Application-specific configuration that is not part of Rails framework defaults.
# This file contains custom settings for your application that make upgrades easier
# by separating them from Rails-generated environment files.

Rails.application.configure do
  # ==> Time Zone Configuration
  config.time_zone = "Central Time (US & Canada)"
  config.active_record.default_timezone = :utc

  # ==> Active Storage Configuration
  # Disable PDF preview generation (requires poppler-utils or mupdf)
  config.active_storage.previewers -= [
    ActiveStorage::Previewer::PopplerPDFPreviewer,
    ActiveStorage::Previewer::MuPDFPreviewer
  ]

  # ==> CORS Configuration
  # Cross-Origin Resource Sharing settings
  # For develoment, you can allow all origins. For production, restrict to your frontend domain.
  config.middleware.insert_before 0, Rack::Cors do
    allow do
      # Development: Allow all origins
      # Production: Replace "*" with specific domain, e.g., "https://your-frontend-app.com"
      origins "*"

      resource "*",
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head]
    end
  end
end
