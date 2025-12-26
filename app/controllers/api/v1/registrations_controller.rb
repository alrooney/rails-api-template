# frozen_string_literal: true

module Api
  module V1
    class RegistrationsController < ApplicationController
      rate_limit to: 10, within: 3.minutes, only: [ :create, :confirm_email, :confirm_phone, :send_phone_confirmation, :send_email_confirmation ], with: -> {
        render json: { error: "Too many requests. Please try again later." }, status: :too_many_requests
      }
      allow_unauthenticated_access only: [ :create, :confirm_email, :confirm_phone, :send_phone_confirmation, :send_email_confirmation ]
      skip_after_action :verify_pundit_authorization, only: [ :create, :confirm_email, :confirm_phone, :send_phone_confirmation, :send_email_confirmation ]

      def create
        @user = User.new(user_params)
        @user.email_confirmed = false
        @user.phone_confirmed = false if @user.phone.present?
        @user.generate_email_confirmation_token

        if @user.save
          # Assign default user role
          @user.add_role(:user)

          UserMailer.confirmation(@user).deliver_later
          if @user.phone.present?
            SmsService.send_verification_code(@user.phone)
            @user.update(phone_confirmation_sent_at: Time.current)
          end

          render json: {
            status: { code: 200, message: "Signed up successfully. Please check your email to confirm your account." + (@user.phone.present? ? " A confirmation code has been sent to your phone." : "") },
            data: UserSerializer.new(@user).serializable_hash[:data][:attributes]
          }, status: :created
        else
          render json: {
            status: { message: "User couldn't be created successfully. #{@user.errors.full_messages.to_sentence}" }
          }, status: :unprocessable_content
        end
      end

      def confirm_email
        user = User.find_by(confirmation_token: params[:token])
        if user && !user.email_confirmed?
          user.confirm_email!
          render json: { message: "Email confirmed successfully. You can now log in." }, status: :ok
        else
          render json: { error: "Invalid or expired confirmation token." }, status: :unprocessable_content
        end
      end

      def confirm_phone
        user = User.find_by(phone: params[:phone])
        if user && !user.phone_confirmed? && SmsService.check_verification_code(user.phone, params[:code])
          user.confirm_phone!
          render json: { message: "Phone number confirmed successfully." }, status: :ok
        else
          render json: { error: "Invalid or expired confirmation code." }, status: :unprocessable_content
        end
      end

      def send_phone_confirmation
        SendPhoneConfirmationJob.perform_later(params[:email])
        render json: { message: "If your account has a phone number, a confirmation code has been sent." }, status: :ok
      end

      def send_email_confirmation
        SendEmailConfirmationJob.perform_later(params[:email])
        render json: { message: "If your account exists and is not confirmed, a confirmation email has been sent." }, status: :ok
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :name, :phone)
      end
    end
  end
end
