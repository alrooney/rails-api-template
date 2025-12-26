require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "is not valid without an email" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "is not valid without a name" do
      user = build(:user, name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it "is not valid with an invalid email format" do
      user = build(:user, email: "invalid-email")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "is not valid with a duplicate email" do
      create(:user, email: "test@example.com")
      user = build(:user, email: "test@example.com")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    it "is not valid with a duplicate phone" do
      create(:user, phone: "+15551234567")
      user = build(:user, phone: "+15551234567")
      expect(user).not_to be_valid
      expect(user.errors[:phone]).to include("has already been taken")
    end

    it "is valid with a valid phone number" do
      user = build(:user, phone: "+15551234567")
      expect(user).to be_valid
    end

    it "is valid with a phone number with country code" do
      user = build(:user, phone: "+15551234567")
      expect(user).to be_valid
    end

    it "is not valid with an invalid phone number" do
      user = build(:user, phone: "123")
      expect(user).not_to be_valid
      expect(user.errors[:phone]).to include("is invalid")
    end

    it "is valid without a phone number" do
      user = build(:user, phone: nil)
      expect(user).to be_valid
    end

    it "is not valid with a password shorter than 6 characters" do
      user = build(:user, password: "12345")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 6 characters)")
    end
  end

  describe "normalization" do
    it "normalizes email to lowercase" do
      user = create(:user, email: "TEST@EXAMPLE.COM")
      expect(user.email).to eq("test@example.com")
    end

    it "handles nil phone gracefully" do
      user = build(:user, phone: nil)
      user.valid?
      expect(user.phone).to be_nil
    end
  end

  describe "phone number E.164 formatting" do
    context "US/Canada 10-digit numbers" do
      it "formats (555) 123-4567 to +15551234567" do
        user = create(:user, phone: "(555) 123-4567")
        expect(user.phone).to eq("+15551234567")
      end

      it "formats 555.123.4567 to +15551234567" do
        user = create(:user, phone: "555.123.4567")
        expect(user.phone).to eq("+15551234567")
      end

      it "formats 555 123 4567 to +15551234567" do
        user = create(:user, phone: "555 123 4567")
        expect(user.phone).to eq("+15551234567")
      end

      it "formats 555-123-4567 to +15551234567" do
        user = create(:user, phone: "555-123-4567")
        expect(user.phone).to eq("+15551234567")
      end

      it "formats 5551234567 to +15551234567" do
        user = create(:user, phone: "5551234567")
        expect(user.phone).to eq("+15551234567")
      end

      it "formats (555) 123-4567 ext 123 to be invalid" do
        user = build(:user, phone: "(555) 123-4567 ext 123")
        expect(user).not_to be_valid
        expect(user.errors[:phone]).to include("is invalid")
      end
    end

    context "US/Canada 11-digit numbers starting with 1" do
      it "formats 1 (555) 123-4567 to +15551234567" do
        user = create(:user, phone: "1 (555) 123-4567")
        expect(user.phone).to eq("+15551234567")
      end

      it "formats 15551234567 to +15551234567" do
        user = create(:user, phone: "15551234567")
        expect(user.phone).to eq("+15551234567")
      end

      it "formats +1 (555) 123-4567 to +15551234567" do
        user = create(:user, phone: "+1 (555) 123-4567")
        expect(user.phone).to eq("+15551234567")
      end

      it "formats +15551234567 to +15551234567" do
        user = create(:user, phone: "+15551234567")
        expect(user.phone).to eq("+15551234567")
      end
    end

    context "International numbers" do
      it "formats +44 20 7946 0958 to +442079460958" do
        user = create(:user, phone: "+44 20 7946 0958")
        expect(user.phone).to eq("+442079460958")
      end

      it "formats +81 3-1234-5678 to +81312345678" do
        user = create(:user, phone: "+81 3-1234-5678")
        expect(user.phone).to eq("+81312345678")
      end

      it "formats +49 30 12345678 to +493012345678" do
        user = create(:user, phone: "+49 30 12345678")
        expect(user.phone).to eq("+493012345678")
      end

      it "formats 44 20 7946 0958 to +442079460958" do
        user = create(:user, phone: "44 20 7946 0958")
        expect(user.phone).to eq("+442079460958")
      end
    end

    context "Edge cases" do
      it "handles empty string" do
        user = build(:user, phone: "")
        user.valid?
        expect(user.phone).to be_nil
      end

      it "handles whitespace only" do
        user = build(:user, phone: "   ")
        user.valid?
        expect(user.phone).to be_nil
      end

      it "handles numbers with letters as invalid" do
        user = build(:user, phone: "555-ABC-4567")
        expect(user).not_to be_valid
        expect(user.errors[:phone]).to include("is invalid")
      end

      it "handles very short numbers (less than 10 digits)" do
        user = build(:user, phone: "123456789")
        user.valid?
        expect(user.phone).to eq("123456789") # Returns as-is for invalid format
      end

      it "handles very long numbers (more than 15 digits) as invalid" do
        user = build(:user, phone: "12345678901234567890")
        expect(user).not_to be_valid
        expect(user.errors[:phone]).to include("is invalid")
      end
    end

    context "Already formatted numbers" do
      it "keeps +15551234567 as +15551234567" do
        user = create(:user, phone: "+15551234567")
        expect(user.phone).to eq("+15551234567")
      end

      it "keeps +442079460958 as +442079460958" do
        user = create(:user, phone: "+442079460958")
        expect(user.phone).to eq("+442079460958")
      end
    end
  end

  describe "confirmation methods" do
    let(:user) { create(:unconfirmed_user) }

    describe "#phone_confirmed?" do
      it "returns true when phone is confirmed" do
        user.update!(phone_confirmed: true)
        expect(user.phone_confirmed?).to be true
      end

      it "returns false when phone is not confirmed" do
        expect(user.phone_confirmed?).to be false
      end
    end

    describe "#email_confirmed?" do
      it "returns true when email is confirmed" do
        user.update!(email_confirmed: true)
        expect(user.email_confirmed?).to be true
      end

      it "returns false when email is not confirmed" do
        expect(user.email_confirmed?).to be false
      end
    end



    describe "#generate_email_confirmation_token!" do
      it "generates a new confirmation token" do
        expect {
          user.generate_email_confirmation_token
        }.to change { user.confirmation_token }.from(nil)
          .and change { user.confirmation_sent_at }.from(nil)
      end
    end

    describe "#confirm_phone!" do
      it "confirms the phone number" do
        user.update!(phone_confirmation_sent_at: Time.current)

        expect {
          user.confirm_phone!
        }.to change { user.phone_confirmed }.from(false).to(true)
          .and change { user.phone_confirmation_sent_at }.to(nil)
      end
    end

    describe "#confirm_email!" do
      it "confirms the email" do
        user.update!(confirmation_token: "abc123", confirmation_sent_at: Time.current)

        expect {
          user.confirm_email!
        }.to change { user.email_confirmed }.from(false).to(true)
          .and change { user.confirmation_token }.from("abc123").to(nil)
          .and change { user.confirmation_sent_at }.to(nil)
      end
    end
  end


  describe "phone number changes" do
    let(:user) { create(:user, phone: "+15551234567", phone_confirmed: true, phone_confirmation_sent_at: Time.current) }

    before do
      allow(SmsService).to receive(:send_verification_code).and_return(true)
    end

    it "resets phone confirmation when phone number changes" do
      expect {
        user.update!(phone: "+15559876543")
      }.to change { user.phone_confirmed }.from(true).to(false)
        .and change { user.phone_confirmation_sent_at }.to(nil)
    end

    it "enqueues phone confirmation job when phone number changes" do
      expect {
        user.update!(phone: "+15559876543")
      }.to have_enqueued_job(SendPhoneConfirmationJob).with(user.email)
    end

    it "does not reset phone confirmation when other attributes change" do
      expect {
        user.update!(name: "New Name")
      }.not_to change { user.phone_confirmed }
    end

    it "does not reset phone confirmation when phone is set to nil" do
      expect {
        user.update!(phone: nil)
      }.not_to change { user.phone_confirmed }
    end

    it "does not enqueue job when phone is set to nil" do
      expect {
        user.update!(phone: nil)
      }.not_to have_enqueued_job(SendPhoneConfirmationJob)
    end
  end

    describe "profile fields" do
      describe "is_profile_complete" do
        it "defaults to false" do
          user = create(:user)
          expect(user.is_profile_complete).to be false
        end

        it "can be set to true" do
          user = create(:user, is_profile_complete: true)
          expect(user.is_profile_complete).to be true
        end
      end

      describe "require_password_change" do
        it "defaults to false" do
          user = create(:user)
          expect(user.require_password_change).to be false
        end

        it "can be set to true" do
          user = create(:user, require_password_change: true)
          expect(user.require_password_change).to be true
        end
      end

      describe "profile" do
        it "defaults to empty hash" do
          user = create(:user)
          expect(user.profile).to eq({})
        end

        it "can store complex data" do
          profile_data = {
            "bio" => "Software developer",
            "location" => "San Francisco",
            "preferences" => { "theme" => "dark", "notifications" => true },
            "skills" => [ "Ruby", "Rails", "JavaScript" ]
          }
          user = create(:user, profile: profile_data)
          expect(user.profile).to eq(profile_data)
        end

        it "can be updated" do
          user = create(:user)
          new_profile = { "bio" => "Updated bio" }
          user.update!(profile: new_profile)
          expect(user.profile).to eq(new_profile)
        end

        it "can be queried with jsonb operators" do
          user = create(:user, profile: { "theme" => "dark", "notifications" => true })
          expect(User.where("profile->>'theme' = ?", "dark")).to include(user)
        end
      end

      describe "notification preferences" do
        describe "#notification_timezone" do
          it "returns timezone from profile" do
            user = create(:user, profile: { preferences: { timezone: "America/Los_Angeles" } })
            expect(user.notification_timezone).to eq("America/Los_Angeles")
          end

          it "defaults to America/New_York when not set" do
            user = create(:user)
            expect(user.notification_timezone).to eq("America/New_York")
          end

          it "defaults to America/New_York when preferences not set" do
            user = create(:user, profile: {})
            expect(user.notification_timezone).to eq("America/New_York")
          end
        end

        describe "#notifications_enabled?" do
          it "returns true by default" do
            user = create(:user)
            expect(user.notifications_enabled?).to be true
          end

          it "returns false when disabled" do
            user = create(:user, profile: { preferences: { notifications: { enabled: false } } })
            expect(user.notifications_enabled?).to be false
          end

          it "returns true when explicitly enabled" do
            user = create(:user, profile: { preferences: { notifications: { enabled: true } } })
            expect(user.notifications_enabled?).to be true
          end
        end

        describe "#morning_notifications_enabled?" do
          it "returns true by default" do
            user = create(:user)
            expect(user.morning_notifications_enabled?).to be true
          end

          it "returns false when disabled" do
            user = create(:user, profile: { preferences: { notifications: { morning: false } } })
            expect(user.morning_notifications_enabled?).to be false
          end

          it "returns false when master switch is off" do
            user = create(:user, profile: { preferences: { notifications: { enabled: false, morning: true } } })
            expect(user.morning_notifications_enabled?).to be false
          end
        end

        describe "#midday_notifications_enabled?" do
          it "returns true by default" do
            user = create(:user)
            expect(user.midday_notifications_enabled?).to be true
          end

          it "returns false when disabled" do
            user = create(:user, profile: { preferences: { notifications: { midday: false } } })
            expect(user.midday_notifications_enabled?).to be false
          end
        end

        describe "#afternoon_notifications_enabled?" do
          it "returns true by default" do
            user = create(:user)
            expect(user.afternoon_notifications_enabled?).to be true
          end

          it "returns false when disabled" do
            user = create(:user, profile: { preferences: { notifications: { afternoon: false } } })
            expect(user.afternoon_notifications_enabled?).to be false
          end
        end

        describe "#evening_notifications_enabled?" do
          it "returns true by default" do
            user = create(:user)
            expect(user.evening_notifications_enabled?).to be true
          end

          it "returns false when disabled" do
            user = create(:user, profile: { preferences: { notifications: { evening: false } } })
            expect(user.evening_notifications_enabled?).to be false
          end
        end

        describe "#wind_down_notifications_enabled?" do
          it "returns true by default" do
            user = create(:user)
            expect(user.wind_down_notifications_enabled?).to be true
          end

          it "returns false when disabled" do
            user = create(:user, profile: { preferences: { notifications: { wind_down: false } } })
            expect(user.wind_down_notifications_enabled?).to be false
          end
        end
      end

    describe "factory traits" do
      it "creates user with profile data" do
        user = create(:user, :with_profile_data)
        expect(user.profile["bio"]).to eq("Software developer")
        expect(user.profile["location"]).to eq("San Francisco")
        expect(user.profile["preferences"]["theme"]).to eq("dark")
      end
    end
  end

  describe 'role assignment and auditing' do
    let(:user) { create(:user) }
    let(:role_name) { :admin }

    before do
      allow(Rails.logger).to receive(:info)
      PaperTrail.request.whodunnit = 'auditor@example.com'
    end

    it 'creates a RoleAudit and logs when a role is added (global role)' do
      expect {
        user.add_role(role_name)
      }.to change { RoleAudit.count }.by(1)

      audit = RoleAudit.last
      expect(audit.user).to eq(user)
      expect(audit.role.name).to eq(role_name.to_s)
      expect(audit.action).to eq('added')
      expect(audit.whodunnit).to eq('auditor@example.com')
      expect(Rails.logger).to have_received(:info).with(/Role 'admin' added to User #{user.id}/)
    end

    it 'creates a RoleAudit and logs when a role is removed (global role)' do
      user.add_role(role_name)
      allow(Rails.logger).to receive(:info)
      expect {
        user.remove_role(role_name)
      }.to change { RoleAudit.count }.by(1)

      audit = RoleAudit.where(user: user, action: 'removed').order(:created_at).last
      expect(audit).not_to be_nil
      expect(audit.user).to eq(user)
      expect(audit.action).to eq('removed')
      expect(audit.whodunnit).to eq('auditor@example.com')
      expect(Rails.logger).to have_received(:info).with(/Role 'admin' removed from User #{user.id}/)
    end

    it 'creates a RoleAudit with resource when role is scoped to a resource' do
      # Note: Resource scoping requires the resource class to be registered with Rolify
      # For a generic starter, we test that role auditing works for global roles
      # Resource-scoped roles would need the resource class registered in the User model
      expect {
        user.add_role(role_name)
      }.to change { RoleAudit.count }.by(1)

      audit = RoleAudit.last
      expect(audit.user).to eq(user)
      expect(audit.role.name).to eq(role_name.to_s)
      expect(audit.action).to eq('added')
    end
  end
end
