module Api
  module V1
    # Lists the seeded countries, so a client can choose an employment country.
    class CountriesController < ApplicationController
      before_action :authenticate!

      def index
        render json: Country.order(:code).map { |country| country_json(country) }
      end

      private

      # The client needs these fields only, so the record is never rendered whole.
      def country_json(country)
        { code: country.code, name: country.name, currency: country.currency }
      end
    end
  end
end
