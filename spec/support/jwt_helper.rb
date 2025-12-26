module JwtHelper
  def generate_jwt_token(user)
    JwtTokenService.generate_auth_token(user)
  end
end

RSpec.configure do |config|
  config.include JwtHelper, type: :request
end
