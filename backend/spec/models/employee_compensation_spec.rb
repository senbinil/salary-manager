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

  describe "nested component attributes" do
    it "creates component rows when the compensation is saved" do
      compensation = create(:employment_contract).employee_compensation
      salary_component = create(:salary_component)

      expect {
        compensation.update!(
          employee_compensation_components_attributes: [
            { salary_component_id: salary_component.id, amount: BigDecimal("1234.5000") }
          ]
        )
      }.to change(EmployeeCompensationComponent, :count).by(1)

      component = compensation.employee_compensation_components.find_by!(salary_component: salary_component)
      expect(component.amount).to eq(BigDecimal("1234.5000"))
    end

    it "updates a component belonging to the compensation by its id" do
      compensation = create(:employment_contract).employee_compensation
      component = compensation.employee_compensation_components.first

      compensation.update!(
        employee_compensation_components_attributes: [
          { id: component.id, amount: BigDecimal("4321.2500") }
        ]
      )

      expect(component.reload.amount).to eq(BigDecimal("4321.2500"))
    end

    it "does not persist invalid nested components" do
      compensation = create(:employment_contract).employee_compensation
      salary_component = create(:salary_component)
      compensation.assign_attributes(
        employee_compensation_components_attributes: [
          { salary_component_id: salary_component.id, amount: -1 }
        ]
      )

      expect(compensation).not_to be_valid
      expect { compensation.save }.not_to change(EmployeeCompensationComponent, :count)
    end

    it "rejects an id belonging to another compensation" do
      compensation = create(:employment_contract).employee_compensation
      foreign_component = create(:employment_contract)
        .employee_compensation.employee_compensation_components.first
      original_amount = foreign_component.amount

      expect {
        compensation.assign_attributes(
          employee_compensation_components_attributes: [
            { id: foreign_component.id, amount: BigDecimal("9999.0000") }
          ]
        )
      }.to raise_error(ActiveRecord::RecordNotFound)
      expect(foreign_component.reload.amount).to eq(original_amount)
    end
  end
end
