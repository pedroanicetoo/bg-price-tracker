FactoryBot.define do
  factory :product do
    sequence(:canonical_name) { |n| "Produto #{n}" }
    category { "boardgame_base" }
    publisher { "Galápagos Jogos" }
    edition  { nil }
    language { "pt-BR" }
    aliases  { [] }

    trait :catan do
      canonical_name { "Catan" }
      publisher      { "Devir" }
    end

    trait :wingspan do
      canonical_name { "Wingspan" }
      publisher      { "Stonemaier Games" }
    end

    trait :expansion do
      category { "expansion" }
    end
  end
end
