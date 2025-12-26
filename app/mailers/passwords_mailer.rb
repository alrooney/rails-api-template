class PasswordsMailer < ApplicationMailer
  def reset(user, token)
    @user = user
    # Handle both string tokens and PasswordResetToken objects
    token_value = token.is_a?(PasswordResetToken) ? token.token : token
    @reset_url = url_for(controller: "api/v1/passwords", action: "update", token: token_value, only_path: false)
    @reset_link = %(<a href="#{@reset_url}">Reset Password</a>).html_safe

    mail to: user.email, subject: "Reset your password"
  end
end
