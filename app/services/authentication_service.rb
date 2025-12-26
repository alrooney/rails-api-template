class AuthenticationService
  def self.authenticate_user(user, request = nil)
    jwt_token = JwtTokenService.generate_auth_token(user)
    refresh_token = RefreshToken.generate_for(user)

    # Return cookie data if request is provided and client supports cookies (web applications)
    cookie_data = nil
    if request && !mobile_client?(request)
      cookie_data = get_auth_cookie_data(jwt_token, refresh_token.token)
    end

    {
      token: jwt_token,
      refresh_token: refresh_token.token,
      user: user,
      message: "Successfully authenticated",
      cookies: cookie_data
    }
  end

  def self.refresh_tokens(refresh_token_value, request = nil)
    if refresh_token_value.blank?
      Rails.logger.info "AuthenticationService: Refresh token is blank"
      return { success: false, error: "Refresh token is required" }
    end

    old_refresh_token = RefreshToken.find_by(token: refresh_token_value)

    if old_refresh_token&.active?
      user = old_refresh_token.user

      # Revoke the old refresh token (token rotation)
      old_refresh_token.revoke!

      # Generate new JWT token
      jwt_token = JwtTokenService.generate_auth_token(user)

      # Generate a new refresh token
      new_refresh_token = RefreshToken.generate_for(user)

      # Return cookie data if request is provided and client supports cookies
      cookie_data = nil
      if request && !mobile_client?(request)
        cookie_data = get_auth_cookie_data(jwt_token, new_refresh_token.token)
      end

      {
        success: true,
        token: jwt_token,
        refresh_token: new_refresh_token.token,
        cookies: cookie_data
      }
    else
      { success: false, error: "Invalid or expired refresh token" }
    end
  end

  def self.logout_user(user, request = nil)
    user.refresh_tokens.active.find_each(&:revoke!)

    # Return cookie clearing data if request is provided and client supports cookies
    cookie_data = nil
    if request && !mobile_client?(request)
      cookie_data = get_clear_cookie_data
    end

    { message: "Successfully logged out", cookies: cookie_data }
  end

  private

  # Detect if the client is a mobile app based on X-Client-Type header
  def self.mobile_client?(request)
    is_mobile = request.headers["X-Client-Type"]&.strip&.downcase == "mobile"

    # Log for debugging
    if is_mobile
      Rails.logger.info "Mobile client detected via X-Client-Type header"
    end

    is_mobile
  end

  def self.get_auth_cookie_data(jwt_token, refresh_token)
    cookie_options = {
      httponly: true,
      secure: Rails.env.production?, # HTTPS only in production
      same_site: :lax # Protects against CSRF
    }

    # Set domain only for production and only if COOKIE_DOMAIN is configured
    if Rails.env.production? && ENV["COOKIE_DOMAIN"].present?
      cookie_options[:domain] = ENV["COOKIE_DOMAIN"]
    end

    {
      jwt_token: cookie_options.merge(
        value: jwt_token,
        expires: 24.hours.from_now
      ),
      refresh_token: cookie_options.merge(
        value: refresh_token,
        expires: 7.days.from_now
      )
    }
  end

  def self.get_clear_cookie_data
    clear_options = {
      value: nil,
      expires: 1.day.ago
    }

    # Include domain in clear cookies if it was set in auth cookies
    if Rails.env.production? && ENV["COOKIE_DOMAIN"].present?
      clear_options[:domain] = ENV["COOKIE_DOMAIN"]
    end

    {
      jwt_token: clear_options.dup,
      refresh_token: clear_options.dup
    }
  end
end
