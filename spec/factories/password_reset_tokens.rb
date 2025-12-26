FactoryBot.define do
  factory :password_reset_token do
    association :user
    token { SecureRandom.urlsafe_base64(32) }
    expires_at { 1.hour.from_now }
    used { false }

    trait :expired do
      expires_at { 1.hour.ago }
    end

    trait :used do
      used { true }
    end
  end
end
