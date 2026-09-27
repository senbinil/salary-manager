module Api
  module V1
    # Lists the employees on record, so a client can browse the organization.
    class EmployeesController < ApplicationController
      include Pagy::Method

      before_action :authenticate!

      def index
        employees = Employee.includes(
          :department,
          :designation,
          active_employment_contracts: [
            :country,
            { employee_compensation: :employee_compensation_components }
          ]
        ).order(:name, :id)
        pagination, employees = pagy(
          :offset,
          employees,
          limit: 20,
          client_limit: 100
        )

        render json: {
          data: employees.map { |employee| employee_list_json(employee) },
          pagination: pagination.data_hash(data_keys: %i[page limit count pages from to previous next])
        }
      end

      def show
        employee = find_employee
        return unless employee

        render json: employee_json(employee).merge(
          total_compensation: employee.total_compensation
        )
      end

      private

      # A missing record answers with our own 404 body rather than letting
      # RecordNotFound surface as a framework error.
      def find_employee
        employee = Employee.includes(
          :department,
          :designation,
          active_employment_contracts: [
            :country,
            { employee_compensation: :employee_compensation_components }
          ]
        ).find_by(id: params[:id])
        render json: { error: "Employee not found" }, status: :not_found unless employee
        employee
      end

      def employee_list_json(employee)
        active_contract = current_active_contract(employee)

        employee_json(employee, active_contract: active_contract).merge(
          total_compensation: active_contract&.total_compensation,
          total_compensation_currency: active_contract&.currency
        )
      end

      # The client needs these fields only, so the record is never rendered whole.
      def employee_json(employee, active_contract: current_active_contract(employee))
        {
          id: employee.id,
          name: employee.name,
          department_id: employee.department_id,
          department_name: employee.department.name,
          designation_id: employee.designation_id,
          designation_name: employee.designation.name,
          user_id: employee.user_id,
          employment_status: active_contract.present? ? "active" : "inactive",
          country_name: active_contract&.country&.name,
          contract_start_date: active_contract&.start_date
        }
      end

      def current_active_contract(employee)
        employee.active_employment_contracts.max_by(&:start_date)
      end
    end
  end
end
