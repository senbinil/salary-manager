module Api
  module V1
    # Lists the departments an employee can belong to.
    class DepartmentsController < ApplicationController
      before_action :authenticate!

      def index
        render json: Department.order(:name).map { |department| department_json(department) }
      end

      private

      # The client needs these fields only, so the record is never rendered whole.
      def department_json(department)
        { id: department.id, name: department.name }
      end
    end
  end
end
