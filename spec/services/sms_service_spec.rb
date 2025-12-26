require 'rails_helper'

RSpec.describe SmsService do
  let(:creds) do
    {
      account_sid: 'ACxxx',
      auth_token: 'auth',
      verify_service_sid: 'VAxxx'
    }
  end

  let(:client) { double('Twilio::REST::Client') }
  let(:verify) { double('verify') }
  let(:v2) { double('v2') }
  let(:services) { double('services') }
  let(:verifications) { double('verifications') }
  let(:verification_checks) { double('verification_checks') }

  before do
    allow(Rails.application).to receive_message_chain(:credentials, :twilio).and_return(creds)
    allow(Twilio::REST::Client).to receive(:new).with('ACxxx', 'auth').and_return(client)
    allow(client).to receive(:verify).and_return(verify)
    allow(verify).to receive(:v2).and_return(v2)
    allow(v2).to receive(:services).with('VAxxx').and_return(services)
    allow(services).to receive(:verifications).and_return(verifications)
    allow(services).to receive(:verification_checks).and_return(verification_checks)
  end

  describe '.send_verification_code' do
    it 'calls Twilio Verify API with the correct phone number' do
      expect(verifications).to receive(:create).with(to: '+15551234567', channel: 'sms').and_return(true)
      expect(SmsService.send_verification_code('+15551234567')).to eq(true)
    end

    it 'returns false when Twilio API raises an error' do
      expect(verifications).to receive(:create).and_raise(StandardError.new('API Error'))
      expect(Rails.logger).to receive(:error).with("Twilio Verify SMS failed: API Error")
      expect(SmsService.send_verification_code('+15551234567')).to eq(false)
    end
  end

  describe '.check_verification_code' do
    it 'returns true when verification code is approved' do
      verification_check = double('verification_check', status: 'approved')
      expect(verification_checks).to receive(:create).with(to: '+15551234567', code: '123456').and_return(verification_check)
      expect(SmsService.check_verification_code('+15551234567', '123456')).to eq(true)
    end

    it 'returns false when verification code is not approved' do
      verification_check = double('verification_check', status: 'denied')
      expect(verification_checks).to receive(:create).with(to: '+15551234567', code: '123456').and_return(verification_check)
      expect(SmsService.check_verification_code('+15551234567', '123456')).to eq(false)
    end

    it 'returns false when verification code is pending' do
      verification_check = double('verification_check', status: 'pending')
      expect(verification_checks).to receive(:create).with(to: '+15551234567', code: '123456').and_return(verification_check)
      expect(SmsService.check_verification_code('+15551234567', '123456')).to eq(false)
    end

    it 'returns false when Twilio API raises an error' do
      expect(verification_checks).to receive(:create).and_raise(StandardError.new('API Error'))
      expect(Rails.logger).to receive(:error).with("Twilio Verify check failed: API Error")
      expect(SmsService.check_verification_code('+15551234567', '123456')).to eq(false)
    end

    it 'calls Twilio Verify API with the correct parameters' do
      verification_check = double('verification_check', status: 'approved')
      expect(verification_checks).to receive(:create).with(to: '+15551234567', code: '123456').and_return(verification_check)
      SmsService.check_verification_code('+15551234567', '123456')
    end
  end
end
