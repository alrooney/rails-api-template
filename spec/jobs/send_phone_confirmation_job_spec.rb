require 'rails_helper'

RSpec.describe SendPhoneConfirmationJob, type: :job do
  include ActiveJob::TestHelper

  let(:email) { 'test@example.com' }

  it 'calls send_verification_code if user exists and has a phone' do
    user = create(:user, email: email, phone: '5551234567', phone_confirmed: false)
    expect(SmsService).to receive(:send_verification_code).with(user.phone)
    described_class.perform_now(email)
  end

  it 'sets phone_confirmation_sent_at when sending verification code' do
    user = create(:user, email: email, phone: '5551234567', phone_confirmed: false)
    allow(SmsService).to receive(:send_verification_code).and_return(true)

    described_class.perform_now(email)

    user.reload
    expect(user.phone_confirmation_sent_at).to be_present
    expect(user.phone_confirmation_sent_at).to be_within(5.seconds).of(Time.current)
  end

  it 'does nothing if the user does not exist' do
    expect(SmsService).not_to receive(:send_verification_code)
    expect {
      described_class.perform_now('nonexistent@example.com')
    }.not_to raise_error
  end

  it 'does nothing if the user has no phone' do
    user = create(:user, email: email, phone: nil)
    expect(SmsService).not_to receive(:send_verification_code)
    described_class.perform_now(email)
  end
end
