FactoryBot.define do
  factory :role_audit do
    user { nil }
    role { nil }
    resource_type { "MyString" }
    resource_id { "" }
    action { "MyString" }
    whodunnit { "MyString" }
  end
end
