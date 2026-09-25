require "rails_helper"

RSpec.describe Department do
  it "requires a name" do
    department = described_class.new(name: nil)

    expect(department).not_to be_valid
    expect(department.errors[:name]).to be_present
  end

  it "requires a unique name" do
    department = create(:department)

    expect(build(:department, name: department.name)).not_to be_valid
  end
end
