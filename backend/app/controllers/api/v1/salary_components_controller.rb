module Api
  module V1
    # Lists the salary components a compensation plan can attach an amount to.
    class SalaryComponentsController < ApplicationController
      before_action :authenticate!

      def index
        render json: SalaryComponent.order(:name).map { |component| component_json(component) }
      end

      private

      # The client needs these fields only, so the record is never rendered whole.
      def component_json(component)
        { id: component.id, name: component.name, category: component.category }
      end
    end
  end
end
