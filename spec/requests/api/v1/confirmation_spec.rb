require 'rails_helper'
require 'swagger_helper'

RSpec.describe "Confirmation API", type: :request do
  include ActiveJob::TestHelper

  path "/api/v1/confirm_phone" do
    post "Confirm phone number" do
      tags "Registrations"
      consumes "application/json"
      parameter name: :phone, in: :body, schema: {
        type: :object,
        properties: {
          phone: { type: :string },
          code: { type: :string }
        },
        required: %w[phone code]
      }

      response "200", "phone confirmed" do
        let(:user) { create(:unconfirmed_user, phone: '5551234567') }
        let(:params) { { phone: user.phone, code: '123456' } }

        before do
          allow(SmsService).to receive(:check_verification_code).with(user.phone, '123456').and_return(true)
        end

        schema type: :object,
          properties: {
            message: { type: :string }
          }

        example "application/json", :success, {
          message: "Phone number confirmed successfully."
        }

        it "confirms the phone if the code is correct" do
          post "/api/v1/confirm_phone", params: params, as: :json
          user.reload
          expect(user.phone_confirmed).to be true
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["message"]).to eq("Phone number confirmed successfully.")
        end
      end

      response "422", "invalid or expired code" do
        let(:user) { create(:unconfirmed_user, phone: '5551234567') }
        let(:params) { { phone: user.phone, code: '000000' } }

        before do
          allow(SmsService).to receive(:check_verification_code).with(user.phone, '000000').and_return(false)
        end

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        example "application/json", :invalid, {
          error: "Invalid or expired confirmation code."
        }

        it "returns an error if the code is invalid" do
          post "/api/v1/confirm_phone", params: params, as: :json
          user.reload
          expect(user.phone_confirmed).to be false
          expect(response).to have_http_status(:unprocessable_content)
          expect(JSON.parse(response.body)["error"]).to eq("Invalid or expired confirmation code.")
        end
      end
    end
  end

  path "/api/v1/send_phone_confirmation" do
    post "Send phone confirmation code" do
      tags "Registrations"
      consumes "application/json"
      parameter name: :email, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email }
        },
        required: %w[email]
      }

      response "200", "confirmation code sent" do
        let(:user) { create(:user_without_phone) }
        let(:email) { { email: user.email } }

        before do
          user.update!(phone: '5551234567', phone_confirmed: false)
        end

        schema type: :object,
          properties: {
            message: { type: :string }
          }

        example "application/json", :success, {
          message: "If your account has a phone number, a confirmation code has been sent."
        }

        it "enqueues the job and returns a generic message" do
          expect {
            post "/api/v1/send_phone_confirmation", params: email, as: :json
          }.to have_enqueued_job(SendPhoneConfirmationJob).with(user.email)
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["message"]).to eq("If your account has a phone number, a confirmation code has been sent.")
        end
      end

      response "200", "confirmation code sent for user not found or no phone" do
        let(:email) { { email: "nonexistent@example.com" } }

        schema type: :object,
          properties: {
            message: { type: :string }
          }

        example "application/json", :success, {
          message: "If your account has a phone number, a confirmation code has been sent."
        }

        it "enqueues the job and returns a generic message" do
          expect {
            post "/api/v1/send_phone_confirmation", params: email, as: :json
          }.to have_enqueued_job(SendPhoneConfirmationJob).with("nonexistent@example.com")
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["message"]).to eq("If your account has a phone number, a confirmation code has been sent.")
        end
      end
    end
  end

  path "/api/v1/send_email_confirmation" do
    post "Send email confirmation" do
      tags "Registrations"
      consumes "application/json"
      parameter name: :email, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email }
        },
        required: %w[email]
      }

      response "200", "confirmation email sent" do
        let(:user) { create(:unconfirmed_user) }
        let(:email) { { email: user.email } }

        schema type: :object,
          properties: {
            message: { type: :string }
          }

        example "application/json", :success, {
          message: "If your account exists and is not confirmed, a confirmation email has been sent."
        }

        it "enqueues the job and returns a generic message" do
          expect {
            post "/api/v1/send_email_confirmation", params: email, as: :json
          }.to have_enqueued_job(SendEmailConfirmationJob).with(user.email)
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["message"]).to eq("If your account exists and is not confirmed, a confirmation email has been sent.")
        end
      end

      response "200", "confirmation email sent for user not found or already confirmed" do
        let(:email) { { email: "nonexistent@example.com" } }

        schema type: :object,
          properties: {
            message: { type: :string }
          }

        example "application/json", :success, {
          message: "If your account exists and is not confirmed, a confirmation email has been sent."
        }

        it "enqueues the job and returns a generic message" do
          expect {
            post "/api/v1/send_email_confirmation", params: email, as: :json
          }.to have_enqueued_job(SendEmailConfirmationJob).with("nonexistent@example.com")
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)["message"]).to eq("If your account exists and is not confirmed, a confirmation email has been sent.")
        end
      end
    end
  end
end
