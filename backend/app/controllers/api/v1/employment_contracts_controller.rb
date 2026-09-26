module Api
  module V1
    # Lists an employee's employment contracts and returns one by id.
    class EmploymentContractsController < ApplicationController
      before_action :authenticate!

      def index
        employee = find_employee
        return unless employee

        contracts = EmploymentContract.where(employee_id: employee.id).order(:start_date)
        render json: contracts.map { |contract| contract_json(contract) }
      end

      def show
        employee = find_employee
        return unless employee

        contract = EmploymentContract.find_by(id: params[:id], employee_id: employee.id)
        return render json: { error: "Employment contract not found" }, status: :not_found unless contract

        render json: contract_json(contract)
      end

      private

      def find_employee
        employee = Employee.find_by(id: params[:employee_id])
        render json: { error: "Employee not found" }, status: :not_found unless employee
        employee
      end

      # Expose the identifiers and dates clients need; never serialize the model
      # wholesale, since its representation is an API contract of its own.
      def contract_json(contract)
        {
          id: contract.id,
          employee_id: contract.employee_id,
          country_code: contract.country_code,
          currency: contract.currency,
          compensation_plan_id: contract.compensation_plan_id,
          start_date: contract.start_date,
          end_date: contract.end_date
        }
      end
    end
  end
end
