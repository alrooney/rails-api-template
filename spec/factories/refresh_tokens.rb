FactoryBot.define do
  factory :refresh_token do
    association :user
    token { SecureRandom.urlsafe_base64(32) }
    expires_at { 7.days.from_now }
    revoked { false }
  end
end
