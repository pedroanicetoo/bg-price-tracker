FactoryBot.define do
  factory :user do
    phone          { "+5562#{Faker::Number.number(digits: 9)}" }
    consent_status { "accepted" }
    consent_at     { 1.day.ago }
    consent_ip     { Faker::Internet.ip_v4_address }
    privacy_policy_version { "1.0" }

    trait :pending do
      phone          { nil }
      consent_status { "pending" }
      consent_at     { nil }
    end

    trait :revoked do
      consent_status { "revoked" }
      anonymized_at  { Time.current }
    end
  end
end
