require "rails_helper"

RSpec.describe EmployeeCompensation do
  it "requires an employment contract and compensation plan tag" do
    compensation = build(:employee_compensation, employment_contract: nil, compensation_plan: nil)

    expect(compensation).not_to be_valid
    expect(compensation.errors[:employment_contract]).to be_present
    expect(compensation.errors[:compensation_plan]).to be_present
  end

  it "requires at least one employee-specific component" do
    compensation = build(:employee_compensation)
    compensation.employee_compensation_components.clear

    expect(compensation).not_to be_valid
    expect(compensation.errors[:employee_compensation_components]).to be_present
  end

  it "allows a plan tag to be reused across employees" do
    plan = create(:compensation_plan)
    first = create(:employment_contract)
    second = create(:employment_contract, employee: create(:employee))

    first.employee_compensation.update!(compensation_plan: plan)
    second.employee_compensation.update!(compensation_plan: plan)

    expect(plan.employee_compensations).to contain_exactly(first.employee_compensation, second.employee_compensation)
  end

  it "keeps amounts for the same salary component employee-specific" do
    salary_component = create(:salary_component)
    first = create(:employment_contract)
    second = create(:employment_contract, employee: create(:employee))
    first_line = first.employee_compensation.employee_compensation_components.first
    second_line = second.employee_compensation.employee_compensation_components.first

    first_line.update!(salary_component: salary_component, amount: 70_000)
    second_line.update!(salary_component: salary_component, amount: 90_000)

    expect(first_line.reload.amount).to eq(70_000)
    expect(second_line.reload.amount).to eq(90_000)
  end

  it "allows at most one compensation per contract" do
    existing = create(:employment_contract).employee_compensation
    duplicate = build(
      :employee_compensation,
      employment_contract: existing.employment_contract,
      compensation_plan: existing.compensation_plan
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:employment_contract_id]).to be_present
  end

  it "enforces the one-to-one contract link in the database" do
    existing = create(:employment_contract).employee_compensation

    expect {
      ActiveRecord::Base.connection.execute(
        "INSERT INTO employee_compensations " \
        "(employment_contract_id, compensation_plan_id, created_at, updated_at) VALUES " \
        "(#{existing.employment_contract_id}, #{existing.compensation_plan_id}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
      )
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
