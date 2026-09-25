require "rails_helper"

RSpec.describe CompensationPlanComponent do
  it "requires an amount" do
    assignment = build(:compensation_plan_component, amount: nil)

    expect(assignment).not_to be_valid
    expect(assignment.errors[:amount]).to be_present
  end

  it "rejects a negative amount" do
    assignment = build(:compensation_plan_component, amount: -0.01)

    expect(assignment).not_to be_valid
    expect(assignment.errors[:amount]).to be_present
  end

  # Zero is a statement, not a gap: "this plan pays nothing for that word" is
  # different from leaving the word off the plan, so it has to stay legal.
  it "accepts a zero amount" do
    expect(build(:compensation_plan_component, amount: 0)).to be_valid
  end

  it "belongs to a plan and a component" do
    assignment = build(:compensation_plan_component, compensation_plan: nil, salary_component: nil)

    expect(assignment).not_to be_valid
    expect(assignment.errors[:compensation_plan]).to be_present
    expect(assignment.errors[:salary_component]).to be_present
  end

  # D0.5: one amount per word per plan. A second row for the same pair would make
  # a plan's total depend on which row a reader happened to count.
  it "allows a component on a plan only once" do
    existing = create(:compensation_plan_component)
    duplicate = build(
      :compensation_plan_component,
      compensation_plan: existing.compensation_plan,
      salary_component: existing.salary_component
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:salary_component_id]).to be_present
  end

  # The validation reads then writes, so two concurrent inserts can both see no
  # row and both succeed. The pair is unique in the database as well, which is
  # what actually holds under load.
  it "rejects a duplicate pair at the database level" do
    existing = create(:compensation_plan_component)

    expect {
      ActiveRecord::Base.connection.execute(
        "INSERT INTO compensation_plan_components " \
        "(compensation_plan_id, salary_component_id, amount) VALUES " \
        "(#{existing.compensation_plan_id}, #{existing.salary_component_id}, 1000)"
      )
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  # The reason definition and amount are separate tables: the same word carries a
  # different amount on each plan, and neither plan owns the word.
  it "lets two plans pay the same component different amounts" do
    component = create(:salary_component)
    first = create(:compensation_plan_component, salary_component: component, amount: 5000)
    second = create(:compensation_plan_component, salary_component: component, amount: 7500)

    expect(first.reload.amount).to eq(5000)
    expect(second.reload.amount).to eq(7500)
  end

  # Amounts are money and get summed, so they must round-trip exactly rather than
  # come back as a float approximation.
  it "keeps the amount at four decimal places" do
    assignment = create(:compensation_plan_component, amount: "1234.5678")

    expect(assignment.reload.amount).to eq(BigDecimal("1234.5678"))
  end
end
