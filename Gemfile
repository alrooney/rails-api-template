source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"
# Use postgresql as the database for Active Record
gem "pg", ">= 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "mission_control-jobs"
gem "propshaft"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

gem "pundit"
gem "rolify"
gem "jsonapi-serializer"
gem "rswag-api"
gem "rswag-ui"

# Authentication
gem "jwt"

# SMS integration
# Note: have to specify version due to incomapatability with jwt 3.x
# see https://github.com/twilio/twilio-ruby/issues/754
gem "twilio-ruby", ">= 7.6.4"

gem "paper_trail"

# JSON schema validation for seeds
gem "json-schema"

# Task recurrence with iCalendar support
gem "ice_cube", "~> 0.16"

group :production do
  # For s3 active storage
  gem "aws-sdk-s3", require: false
end

group :development, :test do
  gem "rspec-rails"
  gem "rswag-specs"
  gem "pundit-matchers"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false
  gem "bundler-audit", require: false

  # Code style and quality
  gem "rubocop-rails-omakase", require: false
  gem "hashie", require: false
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "simplecov"
  gem "shoulda-matchers"
end
