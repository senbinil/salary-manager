module Api
  module V1
    # Lists the employees on record, so a client can browse the organization.
    class EmployeesController < ApplicationController
      before_action :authenticate!

      def index
        render json: Employee.order(:name).map { |employee| employee_json(employee) }
      end

      private

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
