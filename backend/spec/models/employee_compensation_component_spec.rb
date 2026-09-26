require "rails_helper"

RSpec.describe EmployeeCompensationComponent do
  it "requires an amount, employee compensation, and salary component" do
    component = build(
      :employee_compensation_component,
      amount: nil,
      employee_compensation: nil,
      salary_component: nil
    )

    expect(component).not_to be_valid
    expect(component.errors[:amount]).to be_present
    expect(component.errors[:employee_compensation]).to be_present
    expect(component.errors[:salary_component]).to be_present
  end

  it "rejects a negative amount" do
    component = build(:employee_compensation_component, amount: -0.01)

    expect(component).not_to be_valid
    expect(component.errors[:amount]).to be_present
  end

  it "accepts a zero amount" do
    compensation = create(:employment_contract).employee_compensation
    component = build(:employee_compensation_component, employee_compensation: compensation, amount: 0)

    expect(component).to be_valid
  end

  it "allows one salary component only once per employee compensation" do
    existing = create(:employment_contract).employee_compensation.employee_compensation_components.first
    duplicate = build(
      :employee_compensation_component,
      employee_compensation: existing.employee_compensation,
      salary_component: existing.salary_component
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:salary_component_id]).to be_present
  end

  it "enforces component uniqueness in the database" do
    existing = create(:employment_contract).employee_compensation.employee_compensation_components.first

    expect {
      ActiveRecord::Base.connection.execute(
        "INSERT INTO employee_compensation_components " \
        "(employee_compensation_id, salary_component_id, amount, created_at, updated_at) VALUES " \
        "(#{existing.employee_compensation_id}, #{existing.salary_component_id}, 1000, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
      )
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows different employees to have different amounts for the same component" do
    salary_component = create(:salary_component)
    first = create(:employment_contract).employee_compensation.employee_compensation_components.first
    second = create(:employment_contract, employee: create(:employee))
      .employee_compensation.employee_compensation_components.first

    first.update!(salary_component: salary_component, amount: 5000)
    second.update!(salary_component: salary_component, amount: 7500)

    expect(first.reload.amount).to eq(5000)
    expect(second.reload.amount).to eq(7500)
  end

  it "keeps the amount at four decimal places" do
    component = create(:employment_contract)
      .employee_compensation.employee_compensation_components.first
    component.update!(amount: "1234.5678")

    expect(component.reload.amount).to eq(BigDecimal("1234.5678"))
  end
end
