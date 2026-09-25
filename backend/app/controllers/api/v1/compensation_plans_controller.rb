module Api
  module V1
    # Lists the compensation plans a client can browse. A plan carries only a
    # name - its amounts live on its components - so a list needs nothing more.
    class CompensationPlansController < ApplicationController
      before_action :authenticate!

      def index
        render json: CompensationPlan.order(:name).map { |plan| plan_json(plan) }
      end

      private

      # The client needs these fields only, so the record is never rendered whole.
      def plan_json(plan)
        { id: plan.id, name: plan.name }
      end
    end
  end
end
