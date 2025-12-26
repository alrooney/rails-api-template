class JwtTokenService
  def self.generate_token(user, expires_in: 24.hours)
    payload = {
      user_id: user.id,
      exp: expires_in.from_now.to_i
    }

    JWT.encode(payload, Rails.application.credentials.jwt_secret, "HS256")
  end

  def self.generate_auth_token(user)
    generate_token(user, expires_in: 24.hours)
  end

  def self.decode_token(token)
    JWT.decode(token, Rails.application.credentials.jwt_secret, true, algorithm: "HS256")
  rescue JWT::ExpiredSignature
    { error: "Token has expired" }
  rescue JWT::DecodeError
    { error: "Invalid token" }
  end
end
