class ApplicationController < ActionController::API
  include ActionController::Cookies
  include JwtAuthentication
  include Pundit::Authorization
  before_action :set_active_storage_url_options
  before_action :set_paper_trail_whodunnit
  after_action :verify_pundit_authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def verify_pundit_authorization
    if action_name == "index"
      verify_policy_scoped
    else
      verify_authorized
    end
  end

  def user_not_authorized
    render json: { error: "You are not authorized to perform this action." }, status: :forbidden
  end

  def set_active_storage_url_options
    ActiveStorage::Current.url_options = {
      protocol: request.protocol,
      host: request.host,
      port: request.optional_port,
      script_name: request.script_name.presence
    }.compact
  end
end
