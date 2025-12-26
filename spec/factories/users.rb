FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { "password123" }
    email_confirmed { true }
    phone_confirmed { false }
    profile { {} }

    trait :admin do
      after(:create) { |user| user.add_role(:admin) }
    end

    trait :with_phone do
      sequence(:phone) { |n| "+1555#{n.to_s.rjust(7, '0')}" }
      phone_confirmed { true }
    end

    trait :with_profile_data do
      profile { {
        "bio" => "Software developer",
        "location" => "San Francisco",
        "preferences" => { "theme" => "dark", "notifications" => { "enabled" => true } }
      } }
    end
  end

  factory :user_without_phone, class: 'User' do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { "password123" }
    phone { nil }
    email_confirmed { true }
    phone_confirmed { false }
    profile { {} }
  end

  factory :unconfirmed_user, class: 'User' do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { "password123" }
    email_confirmed { false }
    phone_confirmed { false }
    profile { {} }
  end
end
