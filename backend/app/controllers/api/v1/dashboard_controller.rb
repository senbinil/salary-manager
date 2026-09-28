module Api
  module V1
    # Serves the dashboard overview: how many employees are active today, and how
    # they and their current compensation are spread across contract countries.
    class DashboardController < ApplicationController
      before_action :authenticate!

      def summary
        render json: DashboardSummaryQuery.new.call
      end
    end
  end
end
