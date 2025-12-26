module JwtAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_jwt
    # helper_method :authenticated?, :current_user # Removed for API-only app
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :authenticate_jwt, **options
    end
  end

  private
    # def authenticated?
    #   current_user.present?
    # end

    def current_user
      @current_user
    end

    def authenticate_jwt
      token = extract_token
      unless token
        render json: { error: "No token provided" }, status: :unauthorized
        return
      end

      result = JwtTokenService.decode_token(token)
      if result.is_a?(Hash) && result[:error]
        render json: { error: result[:error] }, status: :unauthorized
        return
      end

      payload = result[0]
      @current_user = User.find(payload["user_id"])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :unauthorized
      nil
    end

    def extract_token
      # First try Authorization header (for mobile apps and explicit token passing)
      auth_header = request.headers["Authorization"]
      if auth_header
        return auth_header.split(" ").last
      end

      # Fallback to cookie (for web applications)
      cookies[:jwt_token]
    end
end
