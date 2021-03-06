# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :package do
    quantity    1
    length      { rand(199) + 1 }
    width       { rand(199) + 1 }
    height      { rand(199) + 1 }
    notes       { FFaker::Lorem.paragraph }
    state       'expecting'

    received_at nil
    rejected_at nil

    association :package_type
    association :location

    trait :with_item do
      association :item
    end

    trait :stockit_package do
      inventory_number "123456"
    end

    trait :received do
      state "received"
      received_at { Time.now }
      inventory_number "123456"
    end
  end
end
