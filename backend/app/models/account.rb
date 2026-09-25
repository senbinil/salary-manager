class Account < ApplicationRecord
  include Rodauth::Rails.model

  # Account verification is disabled, so an account is usable as soon as it is
  # created. The database default of 1 ("unverified") is a leftover from the
  # verify_account feature, and an unverified row is unreachable: login and
  # reset-password-request both refuse it, and there is no verification route.
  #
  # This default is for records built through Active Record - rails console,
  # seeds, imports. Rodauth writes the status itself on the create account path,
  # since it goes through Sequel and never instantiates this model. An explicit
  # status still wins, so the factory's :unverified/:closed traits keep working.
  #
  # NOTE: use the enum's own `default:` option rather than a separate
  # `attribute :status, :integer, default: ...` line - re-declaring the
  # attribute replaces the enum type and makes `status` return raw integers.
  enum :status, { unverified: 1, verified: 2, closed: 3 }, default: :verified
end
