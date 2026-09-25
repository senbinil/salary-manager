module Api
  module V1
    # Reports the account behind the current session, so a client can tell
    # whether it is still signed in.
    class MeController < ApplicationController
      before_action :authenticate!

      def show
        account = current_account

        render json: { id: account.id, email: account.email, role: account.role }
      end
    end
  end
end
