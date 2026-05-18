class JwtTokenService
  ALGORITHM = "HS256"
  private_constant :ALGORITHM

  class Error < StandardError; end
  class ExpiredToken < Error; end
  class InvalidToken < Error; end

  def self.generate_token(user, expires_in: 24.hours)
    payload = {
      user_id: user.id,
      exp: expires_in.from_now.to_i
    }

    JWT.encode(payload, Rails.application.credentials.jwt_secret, ALGORITHM)
  end

  def self.generate_auth_token(user)
    generate_token(user, expires_in: 24.hours)
  end

  def self.decode_token(token)
    JWT.decode(token, Rails.application.credentials.jwt_secret, true, algorithm: ALGORITHM)
  rescue JWT::ExpiredSignature
    raise ExpiredToken, "Token has expired"
  rescue JWT::DecodeError
    raise InvalidToken, "Invalid token"
  end
end
