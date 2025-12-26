class UserMailer < ApplicationMailer
  def confirmation(user)
    @user = user
    @confirmation_url = url_for(controller: "api/v1/registrations", action: "confirm_email", token: user.confirmation_token, only_path: false)
    @confirmation_link = %(<a href="#{@confirmation_url}">Confirm Email</a>).html_safe

    mail to: user.email, subject: "Confirm your email address"
  end

  def welcome_email(user)
    @user = user
    # Use a generic dashboard URL - customize based on your frontend
    host = Rails.application.config.action_mailer.default_url_options[:host] || "localhost:3000"
    protocol = Rails.application.config.action_mailer.default_url_options[:protocol] || "http"
    @dashboard_url = "#{protocol}://#{host}/"
    @dashboard_link = %(<a href="#{@dashboard_url}">Open Dashboard</a>).html_safe

    mail to: user.email, subject: "Welcome!"
  end
end
