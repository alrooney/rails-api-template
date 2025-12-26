require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:token) { create(:password_reset_token, user: user) }

  describe "reset" do
    context "when token is a PasswordResetToken object" do
      let(:mail) { described_class.reset(user, token) }

      it "renders the headers" do
        expect(mail.subject).to eq("Reset your password")
        expect(mail.to).to eq([ user.email ])
      end

      it "includes the token in the body" do
        body = mail.body.encoded
        expect(body).to include(token.token)
      end
    end

    context "when token is a string" do
      let(:token_string) { "some-reset-token-string" }
      let(:mail) { described_class.reset(user, token_string) }

      it "renders the headers" do
        expect(mail.subject).to eq("Reset your password")
        expect(mail.to).to eq([ user.email ])
      end

      it "includes the token string in the body" do
        body = mail.body.encoded
        expect(body).to include(token_string)
      end

      it "uses the string token directly without calling .token" do
        # This test ensures the else branch is covered
        # When token is a string, it should be used directly
        expect(mail.body.encoded).to include(token_string)
      end
    end
  end
end
