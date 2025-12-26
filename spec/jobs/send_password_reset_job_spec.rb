require 'rails_helper'

RSpec.describe SendPasswordResetJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user, email: 'test@example.com') }

  it 'sends a password reset email and generates a token if the user exists' do
    perform_enqueued_jobs do
      described_class.perform_later(user.email)
    end
    expect(PasswordResetToken.where(user: user).count).to eq(1)
    expect(ActionMailer::Base.deliveries.last.to).to include(user.email)
  end

  it 'does not raise or send mail if the user does not exist' do
    perform_enqueued_jobs do
      expect {
        described_class.perform_now('nonexistent@example.com')
      }.not_to raise_error
    end
    expect(ActionMailer::Base.deliveries.map(&:to)).not_to include([ 'nonexistent@example.com' ])
  end
end
