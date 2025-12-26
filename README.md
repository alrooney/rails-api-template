# Rails API Starter

A production-ready Rails 8.1 API-only starter template with JWT authentication, user management, and comprehensive testing infrastructure.

## Features

- **Authentication**: JWT-based authentication with refresh tokens, email/phone confirmation, and password reset
- **User Management**: Complete user CRUD operations with role-based access control (RBAC) via Rolify
- **Authorization**: Pundit-based authorization with comprehensive policy coverage
- **API Documentation**: Swagger/OpenAPI documentation with Rswag
- **Testing**: Comprehensive RSpec test suite with 100% line and branch coverage requirements
- **Background Jobs**: Solid Queue for database-backed background jobs with Mission Control UI
- **Versioning**: Paper Trail for model versioning and audit trails
- **Code Quality**: RuboCop, Brakeman, and bundler-audit for security and code quality
- **Active Storage**: File upload support with avatar attachments

## Prerequisites

- Ruby 3.4+ (managed via `mise` recommended)
- PostgreSQL 14+
- `mise` for Ruby version management (recommended)

## Quick Start

### 1. Install Rails (if not already installed)

```bash
# Using mise (recommended)
mise install ruby@3.4.7
mise use ruby@3.4.7
gem install rails

# Or using your preferred Ruby version manager
```

### 2. Create a new project using this starter

```bash
# Clone this repository
git clone <repository-url> my-new-api
cd my-new-api

# Remove existing git history and start fresh
rm -rf .git
git init
git add .
git commit -m "Initial commit from Rails API Starter"

# Or keep the history to see how the starter evolved
# Just rename the remote and continue
```

### 3. Install dependencies

```bash
bundle install
```

### 4. Configure your application

Update the following files with your application name:

- `config/application.rb` - Change `module RailsApiStarter` to your app name
- `config/database.yml` - Update database names from `rails_api_starter_*` to `your_app_*`
- `config/storage.yml` - Update S3 bucket names if using AWS
- `config/deploy.yml` - Update service and image names

### 5. Set up credentials

```bash
# Edit credentials (this will create/update config/credentials/development.key)
rails credentials:edit
```

Add your JWT secret and other configuration:

```yaml
jwt_secret: your-secret-key-here
```

### 6. Database setup

```bash
# Create and setup the database
rails db:create
rails db:migrate
rails db:seed
```

### 7. Start the development server

```bash
bin/dev
```

The API will be available at `http://localhost:3000`

## API Documentation

### Swagger UI
Access the interactive API documentation at: `http://localhost:3000/api-docs`

### Generate Swagger Documentation

After running tests, generate the Swagger YAML:

```bash
rails rswag:specs:swaggerize
```

This will update `swagger/v1/swagger.yaml` with all documented endpoints.

### API Endpoints

#### Authentication
- `POST /api/v1/login` - User login (returns JWT token and refresh token)
- `POST /api/v1/refresh` - Refresh JWT token
- `DELETE /api/v1/logout` - User logout (revokes refresh tokens)

#### Registration
- `POST /api/v1/register` - User registration
- `POST /api/v1/confirm_email` - Confirm email address
- `POST /api/v1/confirm_phone` - Confirm phone number
- `POST /api/v1/send_email_confirmation` - Resend email confirmation
- `POST /api/v1/send_phone_confirmation` - Resend phone confirmation

#### Password Management
- `POST /api/v1/password/reset` - Request password reset
- `PUT /api/v1/password/reset/:token` - Reset password with token

#### User Management
- `GET /api/v1/users/me` - Get current user
- `GET /api/v1/users` - List all users (admin only)
- `GET /api/v1/users/:id` - Get user details
- `PATCH /api/v1/users/:id` - Update user
- `PATCH /api/v1/users/:id/password` - Update user password
- `DELETE /api/v1/users/:id` - Delete user (admin only)

#### Background Jobs UI
- `GET /jobs` - Mission Control Jobs UI (for monitoring background jobs)

## Testing

### Run the test suite

```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/user_spec.rb

# Run with coverage report (generated automatically)
bundle exec rspec
```

### Code coverage

The project uses SimpleCov with **100% line and branch coverage requirements**. Coverage reports are generated automatically when running tests:

- **Local development**: Coverage reports are saved to `coverage/` directory
- **Coverage requirements**: Minimum 100% line coverage and 100% branch coverage enforced

To view coverage locally:
```bash
# Open the HTML coverage report
open coverage/index.html
```

### Code quality checks

```bash
# Run Rubocop (code style)
bundle exec rubocop

# Run Brakeman (security)
bundle exec brakeman

# Run bundle audit (vulnerability check)
bundle exec bundle audit check
```

## Development Tools

### Available bin scripts

```bash
# Start development server with all processes
bin/dev

# Run Rails console
bin/rails console

# Run database migrations
bin/rails db:migrate

# Reset database
bin/rails db:reset

# Run Rubocop
bin/rubocop

# Run Brakeman
bin/brakeman
```

## Database

### Schema
The application uses PostgreSQL with UUID primary keys. Key models include:

- **Users**: Authentication and user management with email/phone confirmation
- **RefreshTokens**: JWT refresh token management
- **PasswordResetTokens**: Secure password reset functionality
- **Roles**: Role-based access control via Rolify
- **RoleAudits**: Audit trail for role assignments

### Migrations
Run migrations with:
```bash
bin/rails db:migrate
```

## Background Jobs

Rails 8 uses [Solid Queue](https://github.com/rails/solid_queue) as the default background job system. No external dependencies (like Sidekiq or Redis) are required.

### Setup

1. **Configure the queue database**
   - In `config/database.yml`, ensure you have a `queue` section (already configured)

2. **Run the queue migration**
   ```bash
   bin/rails db:migrate:queue
   ```

3. **Start the job processor**
   ```bash
   bin/jobs start
   ```

### Monitoring

Access the Mission Control Jobs UI at `http://localhost:3000/jobs` to monitor and manage background jobs.

### Available Jobs

- `SendPasswordResetJob` - Sends password reset emails
- `SendEmailConfirmationJob` - Sends email confirmation emails
- `SendPhoneConfirmationJob` - Sends phone confirmation SMS

## Configuration

### JWT Authentication

JWT tokens are configured via Rails credentials:

```yaml
jwt_secret: your-secret-key-here
```

### CORS

CORS is configured in `config/initializers/cors.rb`. Update production origins as needed.

### Active Storage

Active Storage is configured for file uploads. Update `config/storage.yml` for production S3 configuration.

### SMS Service

Phone confirmation requires SMS service configuration. The starter includes `SmsService` which can be configured for your SMS provider (e.g., Twilio).

## Deployment

### Production setup

1. Set production credentials:
   ```bash
   RAILS_ENV=production rails credentials:edit
   ```

2. Configure environment variables:
   - `DATABASE_URL` - PostgreSQL connection string
   - `RAILS_MASTER_KEY` - Master key for credentials
   - `COOKIE_DOMAIN` - Domain for cookie-based authentication (optional)

3. Precompile assets:
   ```bash
   RAILS_ENV=production rails assets:precompile
   ```

### Docker deployment

The project includes Kamal deployment configuration in `config/deploy.yml`. Update with your server details.

## Project Structure

```
app/
  controllers/
    api/v1/
      authentication_controller.rb  # Login, refresh, logout
      users_controller.rb           # User CRUD operations
      registrations_controller.rb   # Registration, email/phone confirmation
      passwords_controller.rb       # Password reset
  models/
    user.rb                         # User model with roles, email/phone confirmation
    refresh_token.rb                # JWT refresh token management
    password_reset_token.rb         # Password reset token management
    role.rb                         # Rolify role model
    role_audit.rb                   # Role assignment audit trail
  policies/
    user_policy.rb                  # Pundit authorization policies
  serializers/
    user_serializer.rb              # JSON API serialization
    authentication_serializer.rb    # Authentication response serialization
  services/
    authentication_service.rb       # Authentication logic
    jwt_token_service.rb            # JWT token generation/validation
    sms_service.rb                 # SMS sending service
spec/
  requests/api/v1/                  # API endpoint specs with Swagger docs
  models/                           # Model specs
  services/                         # Service specs
  policies/                         # Policy specs
  serializers/                      # Serializer specs
  factories/                        # Factory Bot factories
```

## Extending the Starter

### Adding New Models

1. Generate the model:
   ```bash
   rails generate model YourModel name:string
   ```

2. Create the serializer:
   ```bash
   rails generate serializer YourModel
   ```

3. Create the policy:
   ```bash
   rails generate pundit:policy YourModel
   ```

4. Create the controller:
   ```bash
   rails generate controller api/v1/YourModels
   ```

5. Add Swagger specs in `spec/requests/api/v1/your_models_spec.rb`

6. Add factories in `spec/factories/your_models.rb`

### Adding New Roles

Roles are managed via Rolify. To add a new role:

1. Create the role in seeds or via console:
   ```ruby
   Role.find_or_create_by!(name: 'your_role')
   ```

2. Assign roles to users:
   ```ruby
   user.add_role(:your_role)
   ```

3. Update policies to check for the role:
   ```ruby
   def some_action?
     user.has_role?(:your_role) || user.has_role?(:admin)
   end
   ```

## Contributing

This is a starter template. Feel free to fork and customize for your needs!

## License

This starter template is provided as-is. Customize and use as needed for your projects.
