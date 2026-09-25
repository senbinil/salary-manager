require "rails_helper"

RSpec.describe SalaryComponent do
  it "requires a name" do
    component = build(:salary_component, name: nil)

    expect(component).not_to be_valid
    expect(component.errors[:name]).to be_present
  end

  it "requires a unique name" do
    component = create(:salary_component)

    expect(build(:salary_component, name: component.name)).not_to be_valid
  end

  it "requires a category" do
    component = build(:salary_component, category: nil)

    expect(component).not_to be_valid
    expect(component.errors[:category]).to be_present
  end

  # The integers are persisted, so reordering this mapping would silently change
  # what every existing row means. Pin it.
  it "numbers the categories as the design lists them" do
    expect(described_class.categories).to eq("earning" => 0, "allowance" => 1, "contribution" => 2)
  end
end
