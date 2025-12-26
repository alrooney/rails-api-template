require 'rails_helper'

RSpec.describe AuthenticationService, type: :service do
  let(:user) { create(:user, email_confirmed: true) }
  let(:mock_request) { double('request', cookies: {}, headers: {}) }
  let(:mobile_request) { double('request', cookies: {}, headers: { 'X-Client-Type' => 'mobile' }) }

  describe '.authenticate_user' do
    it 'generates tokens and returns authentication data' do
      result = described_class.authenticate_user(user)

      expect(result[:token]).to be_present
      expect(result[:refresh_token]).to be_present
      expect(result[:user]).to eq(user)
      expect(result[:message]).to eq('Successfully authenticated')
    end

    it 'returns cookie data when request is provided' do
      result = described_class.authenticate_user(user, mock_request)

      expect(result[:cookies]).to be_present
      expect(result[:cookies][:jwt_token]).to include(:value, :httponly, :secure, :same_site, :expires)
      expect(result[:cookies][:refresh_token]).to include(:value, :httponly, :secure, :same_site, :expires)
    end

    it 'does not return cookie data when request is not provided' do
      result = described_class.authenticate_user(user, nil)

      expect(result[:cookies]).to be_nil
    end

    it 'does not return cookie data for mobile clients' do
      result = described_class.authenticate_user(user, mobile_request)

      expect(result[:cookies]).to be_nil
    end

    context 'in production environment' do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it 'sets secure flag to true for cookies' do
        result = described_class.authenticate_user(user, mock_request)

        expect(result[:cookies][:jwt_token][:secure]).to be true
        expect(result[:cookies][:refresh_token][:secure]).to be true
      end

      context 'when COOKIE_DOMAIN is set' do
        before do
          allow(ENV).to receive(:[]).with('COOKIE_DOMAIN').and_return('.example.com')
        end

        it 'sets domain for cookies' do
          result = described_class.authenticate_user(user, mock_request)

          expect(result[:cookies][:jwt_token][:domain]).to eq('.example.com')
          expect(result[:cookies][:refresh_token][:domain]).to eq('.example.com')
        end
      end

      context 'when COOKIE_DOMAIN is not set' do
        before do
          allow(ENV).to receive(:[]).with('COOKIE_DOMAIN').and_return(nil)
        end

        it 'does not set domain for cookies' do
          result = described_class.authenticate_user(user, mock_request)

          expect(result[:cookies][:jwt_token]).not_to have_key(:domain)
          expect(result[:cookies][:refresh_token]).not_to have_key(:domain)
        end
      end

      context 'when COOKIE_DOMAIN is empty' do
        before do
          allow(ENV).to receive(:[]).with('COOKIE_DOMAIN').and_return('')
        end

        it 'does not set domain for cookies' do
          result = described_class.authenticate_user(user, mock_request)

          expect(result[:cookies][:jwt_token]).not_to have_key(:domain)
          expect(result[:cookies][:refresh_token]).not_to have_key(:domain)
        end
      end
    end

    context 'in non-production environment' do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it 'sets secure flag to false for cookies' do
        result = described_class.authenticate_user(user, mock_request)

        expect(result[:cookies][:jwt_token][:secure]).to be false
        expect(result[:cookies][:refresh_token][:secure]).to be false
      end

      it 'does not set domain for cookies even when COOKIE_DOMAIN is set' do
        allow(ENV).to receive(:[]).with('COOKIE_DOMAIN').and_return('.example.com')

        result = described_class.authenticate_user(user, mock_request)

        expect(result[:cookies][:jwt_token]).not_to have_key(:domain)
        expect(result[:cookies][:refresh_token]).not_to have_key(:domain)
      end
    end
  end

  describe '.refresh_tokens' do
    let(:refresh_token) { RefreshToken.generate_for(user) }

    it 'successfully refreshes tokens and generates a new refresh token' do
      old_token_value = refresh_token.token
      result = described_class.refresh_tokens(old_token_value)

      expect(result[:success]).to be true
      expect(result[:token]).to be_present
      expect(result[:refresh_token]).to be_present
      expect(result[:refresh_token]).not_to eq(old_token_value)

      # Verify old token is revoked
      refresh_token.reload
      expect(refresh_token).to be_revoked

      # Verify new token is active
      new_token = RefreshToken.find_by(token: result[:refresh_token])
      expect(new_token).to be_present
      expect(new_token).to be_active
    end

    it 'returns cookie data when request is provided' do
      result = described_class.refresh_tokens(refresh_token.token, mock_request)

      expect(result[:cookies]).to be_present
      expect(result[:cookies][:jwt_token]).to include(:value, :httponly, :secure, :same_site, :expires)
      expect(result[:cookies][:refresh_token]).to include(:value, :httponly, :secure, :same_site, :expires)
    end

    it 'does not return cookie data when request is not provided' do
      old_token_value = refresh_token.token
      result = described_class.refresh_tokens(old_token_value, nil)

      expect(result[:success]).to be true
      expect(result[:token]).to be_present
      expect(result[:refresh_token]).to be_present
      expect(result[:refresh_token]).not_to eq(old_token_value)
      expect(result[:cookies]).to be_nil
    end

    it 'does not return cookie data for mobile clients' do
      old_token_value = refresh_token.token
      result = described_class.refresh_tokens(old_token_value, mobile_request)

      expect(result[:success]).to be true
      expect(result[:token]).to be_present
      expect(result[:refresh_token]).to be_present
      expect(result[:refresh_token]).not_to eq(old_token_value)
      expect(result[:cookies]).to be_nil
    end

    context 'in production environment' do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it 'sets secure flag to true for cookies' do
        result = described_class.refresh_tokens(refresh_token.token, mock_request)

        expect(result[:cookies][:jwt_token][:secure]).to be true
        expect(result[:cookies][:refresh_token][:secure]).to be true
      end

      context 'when COOKIE_DOMAIN is set' do
        before do
          allow(ENV).to receive(:[]).with('COOKIE_DOMAIN').and_return('.example.com')
        end

        it 'sets domain for cookies' do
          result = described_class.refresh_tokens(refresh_token.token, mock_request)

          expect(result[:cookies][:jwt_token][:domain]).to eq('.example.com')
          expect(result[:cookies][:refresh_token][:domain]).to eq('.example.com')
        end
      end

      context 'when COOKIE_DOMAIN is not set' do
        before do
          allow(ENV).to receive(:[]).with('COOKIE_DOMAIN').and_return(nil)
        end

        it 'does not set domain for cookies' do
          result = described_class.refresh_tokens(refresh_token.token, mock_request)

          expect(result[:cookies][:jwt_token]).not_to have_key(:domain)
          expect(result[:cookies][:refresh_token]).not_to have_key(:domain)
        end
      end
    end

    context 'in non-production environment' do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it 'sets secure flag to false for cookies' do
        result = described_class.refresh_tokens(refresh_token.token, mock_request)

        expect(result[:cookies][:jwt_token][:secure]).to be false
        expect(result[:cookies][:refresh_token][:secure]).to be false
      end

      it 'does not set domain for cookies even when COOKIE_DOMAIN is set' do
        allow(ENV).to receive(:[]).with('COOKIE_DOMAIN').and_return('.example.com')

        result = described_class.refresh_tokens(refresh_token.token, mock_request)

        expect(result[:cookies][:jwt_token]).not_to have_key(:domain)
        expect(result[:cookies][:refresh_token]).not_to have_key(:domain)
      end
    end

    it 'returns error for invalid refresh token' do
      result = described_class.refresh_tokens('invalid_token')

      expect(result[:success]).to be false
      expect(result[:error]).to eq('Invalid or expired refresh token')
    end

    it 'returns error for expired refresh token' do
      refresh_token.update!(expires_at: 1.hour.ago)
      result = described_class.refresh_tokens(refresh_token.token)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('Invalid or expired refresh token')
    end

    it 'returns error and logs info when refresh token is blank' do
      expect(Rails.logger).to receive(:info).with('AuthenticationService: Refresh token is blank')

      result = described_class.refresh_tokens(nil)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('Refresh token is required')
    end

    it 'returns error and logs info when refresh token is empty string' do
      expect(Rails.logger).to receive(:info).with('AuthenticationService: Refresh token is blank')

      result = described_class.refresh_tokens('')

      expect(result[:success]).to be false
      expect(result[:error]).to eq('Refresh token is required')
    end

    it 'revokes old token when generating new one' do
      old_token_value = refresh_token.token

      result = described_class.refresh_tokens(old_token_value)

      expect(result[:success]).to be true
      refresh_token.reload
      expect(refresh_token.revoked).to be true
    end

    it 'prevents reuse of old token after rotation' do
      old_token_value = refresh_token.token

      # First refresh
      first_result = described_class.refresh_tokens(old_token_value)
      expect(first_result[:success]).to be true

      # Try to reuse old token - should fail
      second_result = described_class.refresh_tokens(old_token_value)
      expect(second_result[:success]).to be false
      expect(second_result[:error]).to eq('Invalid or expired refresh token')
    end

    it 'allows continuous token refresh without timeout' do
      current_token = refresh_token.token

      # Simulate multiple refreshes (like a mobile app staying logged in)
      5.times do
        result = described_class.refresh_tokens(current_token)
        expect(result[:success]).to be true
        expect(result[:token]).to be_present
        expect(result[:refresh_token]).to be_present

        # Use new token for next refresh
        current_token = result[:refresh_token]
      end

      # Final token should still be active
      final_token = RefreshToken.find_by(token: current_token)
      expect(final_token).to be_present
      expect(final_token).to be_active
    end
  end

  describe '.logout_user' do
    let!(:refresh_token) { RefreshToken.generate_for(user) }

    it 'revokes all active refresh tokens' do
      expect(user.refresh_tokens.active.count).to eq(1)

      result = described_class.logout_user(user)

      expect(result[:message]).to eq('Successfully logged out')
      expect(user.refresh_tokens.active.count).to eq(0)
    end

    it 'returns cookie clearing data when request is provided' do
      result = described_class.logout_user(user, mock_request)

      expect(result[:cookies]).to be_present
      expect(result[:cookies][:jwt_token]).to include(:value, :expires)
      expect(result[:cookies][:refresh_token]).to include(:value, :expires)
    end

    it 'does not return cookie data when request is not provided' do
      result = described_class.logout_user(user, nil)

      expect(result[:cookies]).to be_nil
    end

    it 'does not return cookie data for mobile clients' do
      result = described_class.logout_user(user, mobile_request)

      expect(result[:cookies]).to be_nil
    end

    context 'in production environment' do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      context 'when COOKIE_DOMAIN is set' do
        before do
          allow(ENV).to receive(:[]).with('COOKIE_DOMAIN').and_return('.example.com')
        end

        it 'sets domain for clear cookies' do
          result = described_class.logout_user(user, mock_request)

          expect(result[:cookies][:jwt_token][:domain]).to eq('.example.com')
          expect(result[:cookies][:refresh_token][:domain]).to eq('.example.com')
        end
      end

      context 'when COOKIE_DOMAIN is not set' do
        before do
          allow(ENV).to receive(:[]).with('COOKIE_DOMAIN').and_return(nil)
        end

        it 'does not set domain for clear cookies' do
          result = described_class.logout_user(user, mock_request)

          expect(result[:cookies][:jwt_token]).not_to have_key(:domain)
          expect(result[:cookies][:refresh_token]).not_to have_key(:domain)
        end
      end
    end
  end

  describe '.mobile_client?' do
    let(:web_request) { double('request', headers: {}) }
    let(:mobile_request) { double('request', headers: { 'X-Client-Type' => 'mobile' }) }
    let(:mobile_request_uppercase) { double('request', headers: { 'X-Client-Type' => 'MOBILE' }) }
    let(:mobile_request_with_spaces) { double('request', headers: { 'X-Client-Type' => ' mobile ' }) }
    let(:non_mobile_request) { double('request', headers: { 'X-Client-Type' => 'web' }) }

    it 'returns false for requests without X-Client-Type header' do
      expect(described_class.send(:mobile_client?, web_request)).to be false
    end

    it 'returns true for requests with X-Client-Type: mobile header' do
      expect(described_class.send(:mobile_client?, mobile_request)).to be true
    end

    it 'returns true for requests with X-Client-Type: MOBILE (uppercase)' do
      expect(described_class.send(:mobile_client?, mobile_request_uppercase)).to be true
    end

    it 'returns true for requests with X-Client-Type: " mobile " (with spaces)' do
      expect(described_class.send(:mobile_client?, mobile_request_with_spaces)).to be true
    end

    it 'returns false for requests with X-Client-Type: web' do
      expect(described_class.send(:mobile_client?, non_mobile_request)).to be false
    end

    it 'logs mobile client detection' do
      expect(Rails.logger).to receive(:info).with('Mobile client detected via X-Client-Type header')
      described_class.send(:mobile_client?, mobile_request)
    end
  end
end
