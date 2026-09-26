require "rails_helper"

RSpec.describe EmploymentContractCompensationService do
  describe "#call" do
    it "returns the compensation attached to the given contract with components ordered by amount descending" do
      plan = create(:compensation_plan, name: "Engineering")
      base_salary = create(:salary_component, name: "Z Base Salary", category: :earning)
      housing = create(:salary_component, name: "A Housing Allowance", category: :allowance)
      contract = create(:employment_contract)
      compensation = contract.employee_compensation
      compensation.update!(compensation_plan: plan)
      compensation.employee_compensation_components.first.update!(
        salary_component: base_salary,
        amount: BigDecimal("70000.2500")
      )
      create(
        :employee_compensation_component,
        employee_compensation: compensation,
        salary_component: housing,
        amount: BigDecimal("20000.5000")
      )

      result = described_class.new(contract).call

      expect(result).to eq(
        id: compensation.id,
        compensation_plan: { id: plan.id, name: "Engineering" },
        components: [
          {
            amount: BigDecimal("70000.2500"),
            salary_component: { id: base_salary.id, name: "Z Base Salary", category: "earning" }
          },
          {
            amount: BigDecimal("20000.5000"),
            salary_component: { id: housing.id, name: "A Housing Allowance", category: "allowance" }
          }
        ]
      )
    end
  end
end
