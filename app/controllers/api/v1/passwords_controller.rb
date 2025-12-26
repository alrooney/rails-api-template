# frozen_string_literal: true

module Api
  module V1
    class PasswordsController < ApplicationController
      allow_unauthenticated_access only: [ :create, :update ]
      skip_after_action :verify_pundit_authorization, only: [ :create, :update ]

      def create
        SendPasswordResetJob.perform_later(params[:email])
        render json: { message: "Password reset instructions sent (if user with that email exists)." }
      end

      def update
        token = PasswordResetToken.find_by(token: params[:token])

        if token.nil?
          return render json: { error: "Invalid token" }, status: :unauthorized
        end

        if token.used?
          return render json: { error: "Token has already been used" }, status: :unauthorized
        end

        if token.expired?
          return render json: { error: "Token has expired" }, status: :unauthorized
        end

        if params[:password].blank?
          return render json: { error: "Password is required" }, status: :unprocessable_content
        end

        if token.user.update(password: params[:password])
          token.mark_as_used!
          render json: { message: "Password has been reset." }
        else
          render json: { error: token.user.errors.full_messages.join(", ") }, status: :unprocessable_content
        end
      end
    end
  end
end
