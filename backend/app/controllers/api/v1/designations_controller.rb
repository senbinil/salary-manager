module Api
  module V1
    # Lists the designations (job titles) an employee can hold.
    class DesignationsController < ApplicationController
      before_action :authenticate!

      def index
        render json: Designation.order(:name).map { |designation| designation_json(designation) }
      end

      private

      # The client needs these fields only, so the record is never rendered whole.
      def designation_json(designation)
        { id: designation.id, name: designation.name }
      end
    end
  end
end
