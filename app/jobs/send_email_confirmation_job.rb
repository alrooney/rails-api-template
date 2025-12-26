class SendEmailConfirmationJob < ApplicationJob
  queue_as :default

  def perform(email)
    user = User.find_by(email: email)
    if user && !user.email_confirmed?
      user.generate_email_confirmation_token!
      UserMailer.confirmation(user).deliver_later
    end
    # No-op if user not found or already confirmed
  end
end
