require 'rails_helper'

RSpec.describe RefreshToken, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      token = build(:refresh_token, user: user)
      expect(token).to be_valid
    end

    it 'is not valid without a token' do
      token = build(:refresh_token, user: user, token: nil)
      expect(token).not_to be_valid
      expect(token.errors[:token]).to include("can't be blank")
    end

    it 'is not valid without an expires_at' do
      token = build(:refresh_token, user: user, expires_at: nil)
      expect(token).not_to be_valid
      expect(token.errors[:expires_at]).to include("can't be blank")
    end

    it 'is not valid with a duplicate token' do
      existing_token = create(:refresh_token, user: user)
      token = build(:refresh_token, user: user, token: existing_token.token)
      expect(token).not_to be_valid
      expect(token.errors[:token]).to include('has already been taken')
    end
  end

  describe '.generate_for' do
    it 'creates a new refresh token for a user' do
      expect {
        RefreshToken.generate_for(user)
      }.to change { RefreshToken.count }.by(1)
    end

    it 'generates a unique token' do
      token1 = RefreshToken.generate_for(user)
      token2 = RefreshToken.generate_for(user)
      expect(token1.token).not_to eq(token2.token)
    end

    it 'sets expires_at to 7 days from now' do
      token = RefreshToken.generate_for(user)
      expect(token.expires_at).to be_within(1.second).of(7.days.from_now)
    end
  end

  describe '#expired?' do
    it 'returns true when expires_at is in the past' do
      token = create(:refresh_token, user: user, expires_at: 1.hour.ago)
      expect(token.expired?).to be true
    end

    it 'returns false when expires_at is in the future' do
      token = create(:refresh_token, user: user, expires_at: 1.hour.from_now)
      expect(token.expired?).to be false
    end
  end

  describe '#revoke!' do
    it 'marks the token as revoked' do
      token = create(:refresh_token, user: user, revoked: false)
      token.revoke!
      expect(token.revoked).to be true
    end
  end

  describe '#active?' do
    it 'returns true when token is not revoked and not expired' do
      token = create(:refresh_token, user: user, revoked: false, expires_at: 1.hour.from_now)
      expect(token.active?).to be true
    end

    it 'returns false when token is revoked' do
      token = create(:refresh_token, user: user, revoked: true, expires_at: 1.hour.from_now)
      expect(token.active?).to be false
    end

    it 'returns false when token is expired' do
      token = create(:refresh_token, user: user, revoked: false, expires_at: 1.hour.ago)
      expect(token.active?).to be false
    end
  end

  describe '.active' do
    it 'returns only non-revoked, non-expired tokens' do
      active_token = create(:refresh_token, user: user, revoked: false, expires_at: 1.hour.from_now)
      revoked_token = create(:refresh_token, user: user, revoked: true, expires_at: 1.hour.from_now)
      expired_token = create(:refresh_token, user: user, revoked: false, expires_at: 1.hour.ago)

      active_tokens = RefreshToken.active
      expect(active_tokens).to include(active_token)
      expect(active_tokens).not_to include(revoked_token)
      expect(active_tokens).not_to include(expired_token)
    end
  end
end
