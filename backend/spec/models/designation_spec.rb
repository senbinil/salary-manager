require "rails_helper"

RSpec.describe Designation do
  it "requires a name" do
    designation = described_class.new(name: nil)

    expect(designation).not_to be_valid
    expect(designation.errors[:name]).to be_present
  end

  it "requires a unique name" do
    designation = create(:designation)

    expect(build(:designation, name: designation.name)).not_to be_valid
  end
end
