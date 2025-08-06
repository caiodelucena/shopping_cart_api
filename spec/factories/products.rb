FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Produto #{n}" }
    price { rand(1.0..100.0).round(2) }
  end
end 