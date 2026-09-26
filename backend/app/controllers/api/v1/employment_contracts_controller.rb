module Api
  module V1
    # Lists an employee's employment contracts and returns one by id.
    class EmploymentContractsController < ApplicationController
      before_action :authenticate!

      def index
        employee = find_employee
        return unless employee

        contracts = employee.employment_contracts
          .includes(employee_compensation: [
            :compensation_plan,
            { employee_compensation_components: :salary_component }
          ])
          .order(:start_date)
        render json: contracts.map { |contract| contract_json(contract) }
      end

      def show
        employee = find_employee
        return unless employee

        contract = employee.employment_contracts
          .includes(employee_compensation: [
            :compensation_plan,
            { employee_compensation_components: :salary_component }
          ])
          .find_by(id: params[:id])
        return render json: { error: "Employment contract not found" }, status: :not_found unless contract

        render json: contract_json(contract)
      end

      private

      def find_employee
        employee = Employee.find_by(id: params[:employee_id])
        render json: { error: "Employee not found" }, status: :not_found unless employee
        employee
      end

      # Expose only the fields clients need; never serialize the models wholesale.
      def contract_json(contract)
        compensation = contract.employee_compensation

        {
          id: contract.id,
          employee_id: contract.employee_id,
          country_code: contract.country_code,
          currency: contract.currency,
          compensation_plan_id: compensation.compensation_plan_id,
          start_date: contract.start_date,
          end_date: contract.end_date,
          employee_compensation: employee_compensation_json(compensation)
        }
      end

      def employee_compensation_json(compensation)
        components = compensation.employee_compensation_components
          .sort_by { |component| component.salary_component.name }

        {
          id: compensation.id,
          compensation_plan: {
            id: compensation.compensation_plan_id,
            name: compensation.compensation_plan.name
          },
          components: components.map { |component| employee_compensation_component_json(component) }
        }
      end

      def employee_compensation_component_json(component)
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
  end
end
