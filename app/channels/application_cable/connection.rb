module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private
      def set_current_user
        token = extract_token_from_header
        return unless token

        begin
          decoded_token = JWT.decode(token, Rails.application.credentials.jwt_secret, true, algorithm: "HS256")
          payload = decoded_token[0]
          self.current_user = User.find(payload["user_id"])
        rescue JWT::ExpiredSignature, JWT::DecodeError, ActiveRecord::RecordNotFound
          nil
        end
      end

      def extract_token_from_header
        # ActionCable doesn't have direct access to request headers
        # We need to pass the token in the connection URL
        # Example: ws://localhost:3000/cable?token=your_jwt_token
        request.params[:token]
      end
  end
end
