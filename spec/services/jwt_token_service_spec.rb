require 'rails_helper'

RSpec.describe JwtTokenService, type: :service do
  let(:user) { create(:user) }

  describe '.generate_token' do
    it 'generates a valid JWT token' do
      token = described_class.generate_token(user)

      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3) # JWT has 3 parts
    end

    it 'generates token with custom expiration' do
      token = described_class.generate_token(user, expires_in: 1.hour)

      decoded = JWT.decode(token, Rails.application.credentials.jwt_secret, true, algorithm: 'HS256')
      payload = decoded[0]

      expect(payload['user_id']).to eq(user.id)
      expect(payload['exp']).to be_within(5).of(1.hour.from_now.to_i)
    end
  end

  describe '.generate_auth_token' do
    it 'generates a token with 24 hour expiration' do
      token = described_class.generate_auth_token(user)

      decoded = JWT.decode(token, Rails.application.credentials.jwt_secret, true, algorithm: 'HS256')
      payload = decoded[0]

      expect(payload['user_id']).to eq(user.id)
      expect(payload['exp']).to be_within(5).of(24.hours.from_now.to_i)
    end
  end

  describe '.decode_token' do
    let(:valid_token) { described_class.generate_token(user) }

    it 'successfully decodes a valid token' do
      result = described_class.decode_token(valid_token)

      expect(result).to be_an(Array)
      expect(result[0]['user_id']).to eq(user.id)
    end

    it 'returns error for expired token' do
      expired_token = described_class.generate_token(user, expires_in: -1.hour)
      result = described_class.decode_token(expired_token)

      expect(result).to eq({ error: 'Token has expired' })
    end

    it 'returns error for invalid token' do
      result = described_class.decode_token('invalid.token.here')

      expect(result).to eq({ error: 'Invalid token' })
    end
  end
end
