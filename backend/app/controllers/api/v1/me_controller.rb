module Api
  module V1
    # Reports the account behind the current session, so a client can tell
    # whether it is still signed in.
    class MeController < ApplicationController
      before_action :authenticate!

      def show
        head :ok
      end
    end
  end
end
