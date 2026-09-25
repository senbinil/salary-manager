class ApplicationController < ActionController::API
  private

  # The account for the current session, or nil when signed out.
  def current_account
    rodauth.rails_account
  end

  # Halts a request with the body Rodauth sends when a login is required.
  #
  # This checks that the account still exists rather than only that the session
  # holds an id, so an account closed or deleted after the session was created
  # counts as signed out instead of crashing on a nil account.
  def authenticate!
    return if current_account

    render json: { reason: "login_required", error: "Please login to continue" }, status: :unauthorized
  end

  # Halts a request unless the signed-in account holds one of the allowed roles.
  #
  # Being signed out is answered as unauthenticated rather than forbidden, so a
  # client can tell "please log in" from "you may not do this".
  def require_role!(*roles)
    return authenticate! unless current_account
    return if roles.map(&:to_s).include?(current_account.role)

    render json: { reason: "insufficient_role", error: "You are not allowed to do this" }, status: :forbidden
  end
end
