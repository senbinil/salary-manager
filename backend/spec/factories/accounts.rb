FactoryBot.define do
  factory :account do
    sequence(:email) { |n| "person#{n}@example.com" }
    password { "secret123" }
    status { :unverified }

    trait :verified do
      status { :verified }
    end

    trait :closed do
      status { :closed }
    end

    trait :manager do
      role { :manager }
    end

    trait :hr do
      role { :hr }
    end
  end
end
