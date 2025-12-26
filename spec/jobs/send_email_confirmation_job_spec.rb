require 'rails_helper'

RSpec.describe SendEmailConfirmationJob, type: :job do
  include ActiveJob::TestHelper

  let(:email) { 'test@example.com' }

  it 'generates an email confirmation token and sends email if user exists and is not confirmed' do
    user = create(:unconfirmed_user, email: email)
    expect(user.confirmation_token).to be_nil
    perform_enqueued_jobs do
      described_class.perform_later(email)
    end
    user.reload
    expect(user.confirmation_token).not_to be_nil
    expect(ActionMailer::Base.deliveries.last.to).to include(user.email)
  end

  it 'does nothing if the user does not exist' do
    perform_enqueued_jobs do
      expect {
        described_class.perform_later('nonexistent@example.com')
      }.not_to raise_error
    end
    expect(ActionMailer::Base.deliveries.map(&:to)).not_to include([ 'nonexistent@example.com' ])
  end

  it 'does nothing if the user is already confirmed' do
    user = create(:user, email: email, email_confirmed: true)
    perform_enqueued_jobs do
      described_class.perform_later(email)
    end
    expect(ActionMailer::Base.deliveries.map(&:to)).not_to include([ user.email ])
    expect {
      user.reload
    }.not_to change { user.confirmation_token }
  end
end
