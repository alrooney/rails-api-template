require 'rails_helper'
require 'swagger_helper'

RSpec.describe "Api::V1::Registrations", type: :request do
  path '/api/v1/register' do
    post 'Creates a new user' do
      tags 'Registrations'
      security []
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, format: :email },
              password: { type: :string, format: :password },
              name: { type: :string },
              phone: { type: :string }
            },
            required: %w[email password name]
          }
        }
      }

      response '201', 'user created' do
        let(:user) { { user: { email: 'test@example.com', password: 'password123', name: 'Test User' } } }

        schema type: :object,
          properties: {
            status: {
              type: :object,
              properties: {
                code: { type: :integer },
                message: { type: :string }
              }
            },
            data: {
              type: :object,
              properties: {
                email: { type: :string },
                name: { type: :string },
                phone: { oneOf: [ { type: :string }, { type: :null } ] }
              }
            },
            token: { type: :string }
          }

        example "application/json", :success, {
          status: { code: 200, message: "Signed up successfully. Please check your email to confirm your account." },
          data: { email: "test@example.com", name: "Test User" }
        }

        run_test!
      end

      response '201', 'user created with phone' do
        let(:user) { { user: { email: 'test@example.com', password: 'password123', name: 'Test User', phone: '5551234567' } } }

        before do
          allow(SmsService).to receive(:send_verification_code).and_return(true)
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]["message"]).to include("A confirmation code has been sent to your phone")
        end
      end

      response '422', 'invalid request' do
        let(:user) { { user: { email: 'invalid-email', password: 'short', name: '' } } }

        schema type: :object,
          properties: {
            status: {
              type: :object,
              properties: {
                message: { type: :string }
              }
            }
          }

        example "application/json", :invalid, {
          status: { message: "User couldn't be created successfully. Email is invalid, Password is too short (minimum is 6 characters), Name can't be blank" }
        }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["status"]["message"]).to include("User couldn't be created successfully")
        end
      end
    end
  end

  path '/api/v1/confirm_email' do
    post 'Confirm user email' do
      tags 'Registrations'
      security []
      consumes 'application/json'
      parameter name: :token, in: :body, schema: {
        type: :object,
        properties: {
          token: { type: :string }
        },
        required: %w[token]
      }

      response '200', 'email confirmed' do
        let(:user) { create(:user, email_confirmed: false, confirmation_token: 'abc123', confirmation_sent_at: Time.current) }
        let(:token) { { token: user.confirmation_token } }

        schema type: :object,
          properties: {
            message: { type: :string }
          }

        example "application/json", :success, {
          message: "Email confirmed successfully. You can now log in."
        }

        run_test! do |response|
          user.reload
          expect(user.email_confirmed).to be true
          expect(user.confirmation_token).to be_nil
        end
      end

      response '422', 'invalid or expired token' do
        let(:token) { { token: 'invalidtoken' } }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        example "application/json", :invalid, {
          error: "Invalid or expired confirmation token."
        }

        run_test!
      end
    end
  end

  describe "POST /api/v1/registrations" do
    let(:valid_attributes) do
      {
        user: {
          email: "test@example.com",
          password: "password123",
          name: "Test User"
        }
      }
    end

    let(:valid_attributes_with_phone) do
      {
        user: {
          email: "test@example.com",
          password: "password123",
          name: "Test User",
          phone: "5551234567"
        }
      }
    end

    let(:invalid_attributes) do
      {
        user: {
          email: "invalid-email",
          password: "short",
          name: ""
        }
      }
    end

    before do
      # Stub SmsService.send_verification_code to avoid Twilio calls in tests
      allow(SmsService).to receive(:send_verification_code).and_return(true)

      # Also stub the Twilio client chain for completeness
      creds = {
        account_sid: 'ACxxx',
        auth_token: 'auth',
        verify_service_sid: 'VAxxx'
      }
      allow(Rails.application).to receive_message_chain(:credentials, :twilio).and_return(creds)
      client = double('Twilio::REST::Client')
      verify = double('verify')
      v2 = double('v2')
      services = double('services')
      verifications = double('verifications')
      allow(Twilio::REST::Client).to receive(:new).and_return(client)
      allow(client).to receive(:verify).and_return(verify)
      allow(verify).to receive(:v2).and_return(v2)
      allow(v2).to receive(:services).and_return(services)
      allow(services).to receive(:verifications).and_return(verifications)
      allow(verifications).to receive(:create).and_return(true)
    end

    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post "/api/v1/register", params: valid_attributes, headers: { "ACCEPT" => "application/json" }
        }.to change(User, :count).by(1)
      end

      it "returns a success response with token" do
        post "/api/v1/register", params: valid_attributes, headers: { "ACCEPT" => "application/json" }
        expect(response).to have_http_status(:created)

        json_response = JSON.parse(response.body)
        expect(json_response["status"]["code"]).to eq(200)
        expect(json_response["status"]["message"]).to eq("Signed up successfully. Please check your email to confirm your account.")
        expect(json_response["data"]["email"]).to eq("test@example.com")
        expect(json_response["data"]["name"]).to eq("Test User")
      end
    end

    context "with valid parameters including phone" do
      it "creates a new user with phone" do
        expect {
          post "/api/v1/register", params: valid_attributes_with_phone, headers: { "ACCEPT" => "application/json" }
        }.to change(User, :count).by(1)
      end

      it "returns a success response mentioning phone confirmation" do
        post "/api/v1/register", params: valid_attributes_with_phone, headers: { "ACCEPT" => "application/json" }
        expect(response).to have_http_status(:created)

        json_response = JSON.parse(response.body)
        expect(json_response["status"]["message"]).to include("A confirmation code has been sent to your phone")
        expect(json_response["data"]["phone"]).to eq("+15551234567")
      end

      it "sets phone_confirmation_sent_at when phone is present" do
        post "/api/v1/register", params: valid_attributes_with_phone, headers: { "ACCEPT" => "application/json" }
        expect(response).to have_http_status(:created)

        user = User.find_by(email: "test@example.com")
        expect(user.phone_confirmation_sent_at).to be_present
        expect(user.phone_confirmation_sent_at).to be_within(5.seconds).of(Time.current)
      end
    end

    context "with invalid parameters" do
      it "does not create a new user" do
        expect {
          post "/api/v1/register", params: invalid_attributes, headers: { "ACCEPT" => "application/json" }
        }.not_to change(User, :count)
      end

      it "returns an error response" do
        post "/api/v1/register", params: invalid_attributes, headers: { "ACCEPT" => "application/json" }
        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response["status"]["message"]).to include("User couldn't be created successfully")
      end
    end

    context "with duplicate email" do
      before do
        User.create!(
          email: "test@example.com",
          password: "password123",
          name: "Existing User"
        )
      end

      it "does not create a new user" do
        expect {
          post "/api/v1/register", params: valid_attributes, headers: { "ACCEPT" => "application/json" }
        }.not_to change(User, :count)
      end

      it "returns an error response" do
        post "/api/v1/register", params: valid_attributes, headers: { "ACCEPT" => "application/json" }
        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response["status"]["message"]).to include("Email has already been taken")
      end
    end

    context "when rate limit is exceeded" do
      it "returns 429 Too Many Requests with the correct error message" do
        # Simulate hitting the endpoint more than the allowed rate limit
        10.times do
          post "/api/v1/register", params: valid_attributes, headers: { "ACCEPT" => "application/json" }
        end
        post "/api/v1/register", params: valid_attributes, headers: { "ACCEPT" => "application/json" }
        expect(response).to have_http_status(:too_many_requests)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Too many requests. Please try again later.")
      end
    end
  end
end
