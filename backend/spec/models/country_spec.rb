require "rails_helper"

RSpec.describe Country do
  it "requires a name and currency" do
    country = described_class.new(code: "XX", name: nil, currency: nil)

    expect(country).not_to be_valid
    expect(country.errors[:name]).to be_present
    expect(country.errors[:currency]).to be_present
  end

  it "requires a unique name" do
    country = create(:country)

    expect(build(:country, name: country.name)).not_to be_valid
  end
end
