# Builds the employee-specific compensation payload attached to one contract.
class EmploymentContractCompensationService
  def initialize(contract)
    @contract = contract
  end

  def call
    compensation = @contract.employee_compensation
    components = compensation.employee_compensation_components
      .sort_by { |component| component.salary_component.name }

    {
      id: compensation.id,
      compensation_plan: {
        id: compensation.compensation_plan_id,
        name: compensation.compensation_plan.name
      },
      components: components.map { |component| component_json(component) }
    }
  end

  private

  def component_json(component)
    {
      amount: component.amount,
      salary_component: {
        id: component.salary_component.id,
        name: component.salary_component.name,
        category: component.salary_component.category
      }
    }
  end
end
