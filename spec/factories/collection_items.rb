FactoryBot.define do
  factory :collection_item do
    association :user,    factory: :user
    association :product, factory: :product
    added_at { Time.current }
    notes    { nil }
  end
end
