require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user, confirmation_token: "abc123") }

  describe "confirmation" do
    let(:mail) { described_class.confirmation(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Confirm your email address")
      expect(mail.to).to eq([ user.email ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Confirm Your Email Address")
      expect(mail.body.encoded).to include("abc123")
    end

    it "includes confirmation URL" do
      expect(mail.body.encoded).to include("abc123")
    end
  end

  describe "welcome_email" do
    let(:mail) { described_class.welcome_email(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Welcome!")
      expect(mail.to).to eq([ user.email ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end
end
