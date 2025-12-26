class SmsService
  def self.send_verification_code(phone_number)
    with_twilio_client("Verify SMS") do |client, service_sid|
      client.verify
        .v2
        .services(service_sid)
        .verifications
        .create(to: phone_number, channel: "sms")
      true
    end
  end

  def self.check_verification_code(phone_number, code)
    with_twilio_client("Verify check") do |client, service_sid|
      verification_check = client.verify
        .v2
        .services(service_sid)
        .verification_checks
        .create(to: phone_number, code: code)
      verification_check.status == "approved"
    end
  end

  private

  def self.with_twilio_client(operation)
    creds = Rails.application.credentials.twilio || {}
    client = Twilio::REST::Client.new(
      creds[:account_sid],
      creds[:auth_token]
    )
    service_sid = creds[:verify_service_sid]

    yield client, service_sid
  rescue => e
    Rails.logger.error "Twilio #{operation} failed: #{e.message}"
    false
  end
end
