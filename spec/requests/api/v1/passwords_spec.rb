require "swagger_helper"
require "support/jwt_helper"
require "active_job/test_helper"

RSpec.describe "Password Reset API", type: :request do
  include ActiveJob::TestHelper
  path "/api/v1/password/reset" do
    post "Request password reset" do
      tags "Authentication"
      security []
      consumes "application/json"
      produces "application/json"
      description "Sends password reset instructions to the user's email address. For security, always returns success even if email doesn't exist."

      parameter name: :email, in: :body, schema: {
        type: :object,
        properties: {
          email: {
            type: :string,
            format: :email,
            description: "Email address to send password reset instructions to",
            example: "user@example.com"
          }
        },
        required: %w[email]
      }

      response "200", "success" do
        schema type: :object,
               properties: {
                 message: {
                   type: :string,
                   description: "Success message confirming reset email was sent"
                 }
               },
               required: [ 'message' ]

        example "application/json", :success, {
          message: "Password reset instructions sent (if user with that email exists)."
        }

        let(:user) { create(:user) }
        let(:email) { { email: user.email } }

        run_test! do |response|
          perform_enqueued_jobs
          json = JSON.parse(response.body)
          expect(json["message"]).to include("Password reset instructions sent")
          expect(user.password_reset_tokens.active.count).to eq(1)
        end
      end

      response "200", "success with non-existent email" do
        schema type: :object,
               properties: {
                 message: {
                   type: :string,
                   description: "Success message (same response for security)"
                 }
               },
               required: [ 'message' ]

        example "application/json", :security_response, {
          message: "Password reset instructions sent (if user with that email exists)."
        }

        let(:email) { { email: "nonexistent@example.com" } }

        run_test! do |response|
          perform_enqueued_jobs
          json = JSON.parse(response.body)
          expect(json["message"]).to include("Password reset instructions sent")
        end
      end
    end
  end

  path "/api/v1/password/reset/{token}" do
    put "Reset password with token" do
      tags "Authentication"
      security []
      consumes "application/json"
      produces "application/json"
      description "Resets user password using a valid reset token. Token is obtained from password reset email."

      parameter name: :token, in: :path, type: :string, description: "Password reset token from email"
      parameter name: :password, in: :body, schema: {
        type: :object,
        properties: {
          password: {
            type: :string,
            format: :password,
            description: "New password (minimum 6 characters)",
            example: "newpassword123"
          }
        },
        required: %w[password]
      }

      response "200", "success" do
        schema type: :object,
               properties: {
                 message: {
                   type: :string,
                   description: "Success message confirming password was reset"
                 }
               },
               required: [ 'message' ]

        example "application/json", :success, {
          message: "Password has been reset."
        }

        let(:user) { create(:user) }
        let(:reset_token) { create(:password_reset_token, user: user) }
        let(:token) { reset_token.token }
        let(:password) { { password: "newpassword123" } }

        run_test! do |response|
          put "/api/v1/password/reset/#{token}", params: password.to_json, headers: { "CONTENT_TYPE" => "application/json" }
          json = JSON.parse(response.body)
          expect(json["message"]).to eq("Password has been reset.")
          expect(reset_token.reload.used).to be true
        end
      end

      response "401", "invalid token" do
        schema type: :object,
               properties: {
                 error: {
                   type: :string,
                   description: "Error message for invalid token"
                 }
               },
               required: [ 'error' ]

        example "application/json", :invalid_token, {
          error: "Invalid token"
        }

        let(:token) { "invalid_token" }
        let(:password) { { password: "newpassword123" } }

        run_test! do |response|
          put "/api/v1/password/reset/#{token}", params: password.to_json, headers: { "CONTENT_TYPE" => "application/json" }
          expect(response).to have_http_status(:unauthorized)
        end
      end

      response "401", "used token" do
        schema type: :object,
               properties: {
                 error: {
                   type: :string,
                   description: "Error message for already used token"
                 }
               },
               required: [ 'error' ]

        example "application/json", :used_token, {
          error: "Token has already been used"
        }

        let(:user) { create(:user) }
        let(:reset_token) { create(:password_reset_token, :used, user: user) }
        let(:token) { reset_token.token }
        let(:password) { { password: "newpassword123" } }

        run_test! do |response|
          put "/api/v1/password/reset/#{token}", params: password.to_json, headers: { "CONTENT_TYPE" => "application/json" }
          expect(response).to have_http_status(:unauthorized)
        end
      end

      response "401", "expired token" do
        schema type: :object,
               properties: {
                 error: {
                   type: :string,
                   description: "Error message for expired token"
                 }
               },
               required: [ 'error' ]

        example "application/json", :expired_token, {
          error: "Token has expired"
        }

        let(:user) { create(:user) }
        let(:reset_token) { create(:password_reset_token, :expired, user: user) }
        let(:token) { reset_token.token }
        let(:password) { { password: "newpassword123" } }

        run_test! do |response|
          put "/api/v1/password/reset/#{token}", params: password.to_json, headers: { "CONTENT_TYPE" => "application/json" }
          expect(response).to have_http_status(:unauthorized)
        end
      end

      response "422", "blank password" do
        schema type: :object,
               properties: {
                 error: {
                   type: :string,
                   description: "Validation error message"
                 }
               },
               required: [ 'error' ]

        example "application/json", :blank_password, {
          error: "Password is required"
        }

        let(:user) { create(:user) }
        let(:reset_token) { create(:password_reset_token, user: user) }
        let(:token) { reset_token.token }
        let(:password) { { password: "" } }

        run_test! do |response|
          put "/api/v1/password/reset/#{token}", params: password.to_json, headers: { "CONTENT_TYPE" => "application/json" }
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Password is required")
        end
      end

      response "422", "invalid password" do
        schema type: :object,
               properties: {
                 error: {
                   type: :string,
                   description: "Validation error message"
                 }
               },
               required: [ 'error' ]

        example "application/json", :validation_error, {
          error: "Password is too short (minimum is 6 characters)"
        }

        let(:user) { create(:user) }
        let(:reset_token) { create(:password_reset_token, user: user) }
        let(:token) { reset_token.token }
        let(:password) { { password: "short" } }

        run_test! do |response|
          put "/api/v1/password/reset/#{token}", params: password.to_json, headers: { "CONTENT_TYPE" => "application/json" }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end
end
