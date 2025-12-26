class SendPhoneConfirmationJob < ApplicationJob
  queue_as :default

  def perform(email)
    user = User.find_by(email: email)
    if user&.phone.present?
      SmsService.send_verification_code(user.phone)
      user.update(phone_confirmation_sent_at: Time.current)
    end
    # No-op if user/phone not found
  end
end
