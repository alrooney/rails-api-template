class SendPasswordResetJob < ApplicationJob
  queue_as :mailers

  def perform(email)
    user = User.find_by(email: email)
    if user
      # Invalidate any existing active tokens
      user.password_reset_tokens.active.update_all(used: true)
      # Generate new token
      token = PasswordResetToken.generate_for(user)
      PasswordsMailer.reset(user, token).deliver_now
    end
  end
end
