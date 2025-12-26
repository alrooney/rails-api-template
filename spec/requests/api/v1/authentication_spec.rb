require "swagger_helper"
require "support/jwt_helper"

RSpec.describe "Authentication API", type: :request do
  path "/api/v1/login" do
    post "Login to get JWT token" do
      tags "Authentication"
      security []
      consumes "application/json"
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email },
          password: { type: :string, format: :password }
        },
        required: %w[email password]
      }

      response "200", "login with unconfirmed phone" do
        let(:user) { create(:user, password: "password123", email_confirmed: true, phone: "5551234567", phone_confirmed: false) }
        let(:credentials) { { email: user.email, password: "password123" } }

        schema type: :object,
          properties: {
            token: { type: :string },
            refresh_token: { type: :string },
            user: {
              type: :object,
              properties: {
                id: { type: :string },
                email: { type: :string }
              }
            },
            message: { type: :string }
          }

        example "application/json", :success, {
          token: "jwt.token.here",
          refresh_token: "refresh.token.here",
          user: { id: "uuid", email: "user@example.com" },
          message: "Successfully logged in"
        }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json).to include("token")
          expect(json).to include("refresh_token")
          expect(json["token"]).to be_a(String)
          expect(json["refresh_token"]).to be_a(String)

          # Test that cookies are being set
          expect(response.cookies['jwt_token']).to be_present
          expect(response.cookies['refresh_token']).to be_present
          expect(response.cookies['jwt_token']).to eq(json["token"])
          expect(response.cookies['refresh_token']).to eq(json["refresh_token"])
        end
      end

      response "200", "success" do
        let(:user) { create(:user, password: "password123", email_confirmed: true) }
        let(:credentials) { { email: user.email, password: "password123" } }

        schema type: :object,
          properties: {
            token: { type: :string },
            refresh_token: { type: :string },
            user: {
              type: :object,
              properties: {
                id: { type: :string },
                email: { type: :string }
              }
            },
            message: { type: :string }
          }

        example "application/json", :success, {
          token: "jwt.token.here",
          refresh_token: "refresh.token.here",
          user: { id: "uuid", email: "user@example.com" },
          message: "Successfully logged in"
        }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json).to include("token")
          expect(json).to include("refresh_token")
          expect(json["token"]).to be_a(String)
          expect(json["refresh_token"]).to be_a(String)

          # Test that cookies are being set
          expect(response.cookies['jwt_token']).to be_present
          expect(response.cookies['refresh_token']).to be_present
          expect(response.cookies['jwt_token']).to eq(json["token"])
          expect(response.cookies['refresh_token']).to eq(json["refresh_token"])
        end
      end

      response "401", "unauthorized" do
        let(:credentials) { { email: "invalid@example.com", password: "wrong" } }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        example "application/json", :unauthorized, {
          error: "Invalid credentials"
        }

        run_test!
      end
    end
  end

  path "/api/v1/refresh" do
    post "Refresh JWT token" do
      tags "Authentication"
      security []
      consumes "application/json"
      parameter name: :refresh_token, in: :body, schema: {
        type: :object,
        properties: {
          refresh_token: { type: :string }
        },
        required: %w[refresh_token]
      }

      response "200", "success" do
        let(:user) { create(:user, email_confirmed: true) }
        let(:refresh_token) { { refresh_token: create(:refresh_token, user: user).token } }

        schema type: :object,
          properties: {
            token: { type: :string }
          }

        example "application/json", :success, {
          token: "jwt.token.here"
        }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json).to include("token")
          expect(json["token"]).to be_a(String)

          # Test that cookies are being updated
          expect(response.cookies['jwt_token']).to be_present
          expect(response.cookies['refresh_token']).to be_present
          expect(response.cookies['jwt_token']).to eq(json["token"])
        end
      end

      response "401", "unauthorized" do
        let(:refresh_token) { { refresh_token: "invalid_token" } }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        example "application/json", :unauthorized, {
          error: "Invalid or expired refresh token"
        }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["error"]).to eq("Invalid or expired refresh token")
        end
      end
    end
  end

  path "/api/v1/logout" do
    delete "Logout and invalidate JWT token" do
      tags "Authentication"
      security [
        { bearer_auth: [] },
        { cookie_auth: [] }
      ]

      response "200", "success" do
        let(:user) { create(:user, email_confirmed: true) }
        let!(:refresh_token) { create(:refresh_token, user: user).token }
        let(:Authorization) { "Bearer #{generate_jwt_token(user)}" }

        schema type: :object,
          properties: {
            message: { type: :string }
          }

        example "application/json", :success, {
          message: "Successfully logged out"
        }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["message"]).to eq("Successfully logged out")

          # Test that cookies are being cleared
          expect(response.cookies['jwt_token']).to be_nil
          expect(response.cookies['refresh_token']).to be_nil
        end
      end

      response "401", "expired token" do
        let(:user) { create(:user, email_confirmed: true) }
        let(:expired_token) do
          JWT.encode({ user_id: user.id, exp: 1.hour.ago.to_i }, Rails.application.credentials.jwt_secret, "HS256")
        end
        let(:Authorization) { "Bearer #{expired_token}" }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        example "application/json", :unauthorized, {
          error: "Token has expired"
        }

        run_test! do |response|
          expect(response.body).to include("Token has expired")
        end
      end

      response "401", "user not found" do
        let(:token) do
          JWT.encode({ user_id: "nonexistent", exp: 1.hour.from_now.to_i }, Rails.application.credentials.jwt_secret, "HS256")
        end
        let(:Authorization) { "Bearer #{token}" }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        example "application/json", :unauthorized, {
          error: "User not found"
        }

        run_test! do |response|
          expect(response.body).to include("User not found")
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid_token" }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        example "application/json", :unauthorized, {
          error: "Invalid credentials"
        }

        run_test!
      end
    end
  end

  describe "DELETE /api/v1/logout without Authorization header" do
    it "returns 401 with 'No token provided'" do
      delete "/api/v1/logout"
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include("No token provided")
    end
  end

  describe "POST /api/v1/login rate limiting on failed logins" do
    let(:user) { create(:user, password: "password123", email_confirmed: true) }
    let(:invalid_credentials) { { email: user.email, password: "wrongpassword" } }

    it "returns 429 after too many failed login attempts" do
      10.times do
        post "/api/v1/login", params: invalid_credentials.to_json, headers: { "CONTENT_TYPE" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end

      # The 11th request should be rate limited
      post "/api/v1/login", params: invalid_credentials.to_json, headers: { "CONTENT_TYPE" => "application/json" }
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("Too many requests")
    end
  end

  describe "POST /api/v1/login with unconfirmed email" do
    let(:user) { create(:user, password: "password123", email_confirmed: false) }
    let(:credentials) { { email: user.email, password: "password123" } }

    it "returns 401 and requires email confirmation" do
      post "/api/v1/login", params: credentials.to_json, headers: { "CONTENT_TYPE" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include("You must confirm your email address before logging in")
    end
  end

  describe "Authentication endpoints when no cookies are returned" do
    describe "POST /api/v1/login when AuthenticationService returns nil cookies" do
      let(:user) { create(:user, password: "password123", email_confirmed: true) }
      let(:credentials) { { email: user.email, password: "password123" } }

      before do
        allow(AuthenticationService).to receive(:authenticate_user).and_return({
          token: "jwt.token.here",
          refresh_token: "refresh.token.here",
          user: user,
          message: "Successfully authenticated",
          cookies: nil  # This should trigger the else branch
        })
      end

      it "does not set cookies when AuthenticationService returns nil cookies" do
        post "/api/v1/login", params: credentials.to_json, headers: { "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to include("token", "refresh_token", "user", "message")

        # Cookies should not be set
        expect(response.cookies['jwt_token']).to be_nil
        expect(response.cookies['refresh_token']).to be_nil
      end
    end

    describe "POST /api/v1/refresh when AuthenticationService returns nil cookies" do
      let(:user) { create(:user, email_confirmed: true) }
      let(:refresh_token) { { refresh_token: create(:refresh_token, user: user).token } }

      before do
        allow(AuthenticationService).to receive(:refresh_tokens).and_return({
          success: true,
          token: "new.jwt.token.here",
          refresh_token: "refresh.token.here",
          cookies: nil  # This should trigger the else branch
        })
      end

      it "does not set cookies when AuthenticationService returns nil cookies" do
        post "/api/v1/refresh", params: refresh_token.to_json, headers: { "CONTENT_TYPE" => "application/json" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to include("token")

        # Cookies should not be set
        expect(response.cookies['jwt_token']).to be_nil
        expect(response.cookies['refresh_token']).to be_nil
      end
    end

    describe "DELETE /api/v1/logout when AuthenticationService returns nil cookies" do
      let(:user) { create(:user, email_confirmed: true) }
      let!(:refresh_token) { create(:refresh_token, user: user).token }
      let(:auth_header) { "Bearer #{generate_jwt_token(user)}" }

      before do
        allow(AuthenticationService).to receive(:logout_user).and_return({
          message: "Successfully logged out",
          cookies: nil  # This should trigger the else branch
        })
      end

      it "does not clear cookies when AuthenticationService returns nil cookies" do
        delete "/api/v1/logout", headers: { "Authorization" => auth_header }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["message"]).to eq("Successfully logged out")

        # Cookies should not be cleared (they should remain unchanged)
        expect(response.cookies['jwt_token']).to be_nil
        expect(response.cookies['refresh_token']).to be_nil
      end
    end
  end
end
