require 'rails_helper'

RSpec.describe PasswordResetToken, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      token = build(:password_reset_token, user: user)
      expect(token).to be_valid
    end

    it 'is not valid without a token' do
      token = build(:password_reset_token, user: user, token: nil)
      expect(token).not_to be_valid
      expect(token.errors[:token]).to include("can't be blank")
    end

    it 'is not valid without an expires_at' do
      token = build(:password_reset_token, user: user, expires_at: nil)
      expect(token).not_to be_valid
      expect(token.errors[:expires_at]).to include("can't be blank")
    end

    it 'is not valid with a duplicate token' do
      existing_token = create(:password_reset_token, user: user)
      token = build(:password_reset_token, user: user, token: existing_token.token)
      expect(token).not_to be_valid
      expect(token.errors[:token]).to include('has already been taken')
    end
  end

  describe '.generate_for' do
    it 'creates a new password reset token for a user' do
      expect {
        PasswordResetToken.generate_for(user)
      }.to change { PasswordResetToken.count }.by(1)
    end

    it 'generates a unique token' do
      token1 = PasswordResetToken.generate_for(user)
      token2 = PasswordResetToken.generate_for(user)
      expect(token1.token).not_to eq(token2.token)
    end

    it 'sets expires_at to 1 hour from now' do
      token = PasswordResetToken.generate_for(user)
      expect(token.expires_at).to be_within(1.second).of(1.hour.from_now)
    end
  end

  describe '#expired?' do
    it 'returns true when expires_at is in the past' do
      token = create(:password_reset_token, user: user, expires_at: 1.hour.ago)
      expect(token.expired?).to be true
    end

    it 'returns false when expires_at is in the future' do
      token = create(:password_reset_token, user: user, expires_at: 1.hour.from_now)
      expect(token.expired?).to be false
    end
  end

  describe '#mark_as_used!' do
    it 'marks the token as used' do
      token = create(:password_reset_token, user: user, used: false)
      token.mark_as_used!
      expect(token.used).to be true
    end
  end

  describe '#used?' do
    it 'returns true when token is used' do
      token = create(:password_reset_token, user: user, used: true)
      expect(token.used?).to be true
    end

    it 'returns false when token is not used' do
      token = create(:password_reset_token, user: user, used: false)
      expect(token.used?).to be false
    end
  end

  describe '.active' do
    it 'returns only non-used, non-expired tokens' do
      active_token = create(:password_reset_token, user: user, used: false, expires_at: 1.hour.from_now)
      used_token = create(:password_reset_token, user: user, used: true, expires_at: 1.hour.from_now)
      expired_token = create(:password_reset_token, user: user, used: false, expires_at: 1.hour.ago)

      active_tokens = PasswordResetToken.active
      expect(active_tokens).to include(active_token)
      expect(active_tokens).not_to include(used_token)
      expect(active_tokens).not_to include(expired_token)
    end
  end
end
