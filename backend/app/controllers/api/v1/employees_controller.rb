module Api
  module V1
    # Lists the employees on record, so a client can browse the organization.
    class EmployeesController < ApplicationController
      before_action :authenticate!

      def index
        render json: Employee.order(:name).map { |employee| employee_json(employee) }
      end

      def show
        employee = find_employee
        return unless employee

        render json: employee_json(employee)
      end

      private

      # A missing record answers with our own 404 body rather than letting
      # RecordNotFound surface as a framework error.
      def find_employee
        employee = Employee.find_by(id: params[:id])
        render json: { error: "Employee not found" }, status: :not_found unless employee
        employee
      end

      # The client needs these fields only, so the record is never rendered whole.
      def employee_json(employee)
        {
          id: employee.id,
          name: employee.name,
          department_id: employee.department_id,
          designation_id: employee.designation_id,
          user_id: employee.user_id
        }
      end
    end
  end
end
