require "rails_helper"

RSpec.describe CompensationPlan do
  it "requires a name" do
    plan = build(:compensation_plan, name: nil)

    expect(plan).not_to be_valid
    expect(plan.errors[:name]).to be_present
  end

  it "requires a unique name" do
    plan = create(:compensation_plan)

    expect(build(:compensation_plan, name: plan.name)).not_to be_valid
  end
end
