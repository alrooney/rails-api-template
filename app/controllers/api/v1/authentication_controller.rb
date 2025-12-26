# app/controllers/api/v1/authentication_controller.rb
# frozen_string_literal: true

module Api
  module V1
    class AuthenticationController < ApplicationController
      rate_limit to: 10, within: 3.minutes, only: [ :login, :refresh ], with: -> {
        render json: { error: "Too many requests. Please try again later." }, status: :too_many_requests
      }

      allow_unauthenticated_access only: [ :login, :refresh ]
      skip_after_action :verify_pundit_authorization, only: [ :login, :refresh, :logout ]

      def login
        @user = User.find_by(email: params[:email])
        if @user&.authenticate(params[:password])
          unless @user.email_confirmed?
            return render json: { error: "You must confirm your email address before logging in." }, status: :unauthorized
          end

          # Note: Phone confirmation is not required for login to allow users to correct incorrect phone numbers
          # Phone confirmation can be required for sensitive operations instead

          auth_result = AuthenticationService.authenticate_user(@user, request)

          # Set cookies if the service returned cookie data
          if auth_result[:cookies]
            auth_result[:cookies].each do |name, options|
              cookies[name] = options
            end
          end

          render json: AuthenticationSerializer.serialize_login_response(auth_result, @user), status: :ok
        else
          render json: { error: "Invalid credentials" }, status: :unauthorized
        end
      end

      def refresh
        # Try to get refresh token from cookies first, then from JSON body
        refresh_token_value = cookies[:refresh_token] || params[:refresh_token]
        result = AuthenticationService.refresh_tokens(refresh_token_value, request)

        if result[:success]
          # Set cookies if the service returned cookie data
          if result[:cookies]
            result[:cookies].each do |name, options|
              cookies[name] = options
            end
          end

          render json: AuthenticationSerializer.serialize_refresh_response(result), status: :ok
        else
          render json: { error: result[:error] }, status: :unauthorized
        end
      end

      def logout
        result = AuthenticationService.logout_user(current_user, request)

        # Clear cookies if the service returned cookie clearing data
        if result[:cookies]
          result[:cookies].each do |name, options|
            cookies[name] = options
          end
        end

        render json: { message: result[:message] }, status: :ok
      end
    end
  end
end
