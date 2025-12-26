class AuthenticationSerializer
  include JSONAPI::Serializer

  # Custom serialization for authentication responses
  def self.serialize_login_response(auth_result, user)
    {
      token: auth_result[:token],
      refresh_token: auth_result[:refresh_token],
      user: serialize_user_for_auth(user),
      message: auth_result[:message]
    }
  end

  def self.serialize_refresh_response(auth_result)
    {
      token: auth_result[:token]
    }
  end

  private

  # Serialize user data for authentication responses
  # Maintains backward compatibility by only including id and email
  def self.serialize_user_for_auth(user)
    {
      id: user.id,
      email: user.email
    }
  end
end
