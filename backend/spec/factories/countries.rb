FactoryBot.define do
  factory :country do
    sequence(:code) { |n| n.to_s(36).rjust(2, "0") } # 2-char ISO-style codes, unique
    sequence(:name) { |n| "Country #{n}" }
    currency { "USD" }
  end
end
