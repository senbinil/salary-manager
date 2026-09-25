# The source of truth for how an employee is paid (§1): one currency, one
# compensation plan, and the date range they apply to. An end date is how a
# contract terminates - there is no delete. Nothing is effective-dated, so editing
# a contract changes what past reports show (§6.5).
class EmploymentContract < ApplicationRecord
  belongs_to :employee
  # Country is keyed by its ISO code rather than an id, so the foreign key is
  # country_code and not the country_id the association would assume.
  belongs_to :country, foreign_key: :country_code
  belongs_to :compensation_plan

  # §3: the country supplies the currency, and a contract may override it (an
  # expat in India paid in USD keeps India as the contract country). Create only:
  # once set, a currency is not silently re-derived from the country.
  before_validation :copy_currency_from_country, on: :create

  validates :currency, presence: true
  validates :start_date, presence: true
  validate :end_date_after_start_date
  validate :no_overlapping_contracts

  private

  def copy_currency_from_country
    self.currency = country.currency if currency.blank? && country
  end

  # A null end_date is open-ended, so only compare when both dates are present.
  # The rule is "after" rather than "on or after" - the same CHECK is in the
  # database - so a contract cannot start and end on the same day.
  def end_date_after_start_date
    return if start_date.blank? || end_date.blank? || end_date > start_date

    errors.add(:end_date, "must come after the start date")
  end

  # §7: one contract at a time, so an employee's ranges must not intersect. This
  # reads before it writes, which is why the partial unique index exists as well.
  def no_overlapping_contracts
    return if employee_id.blank? || start_date.blank?
    return unless overlapping_contract?

    errors.add(:start_date, "overlaps another contract for this employee")
  end

  def overlapping_contract?
    others = EmploymentContract.where(employee_id: employee_id)
    others = others.where.not(id: id) if persisted?

    # Ranges include their end date, and a null end_date runs to infinity - so an
    # open-ended contract clashes with anything starting on or after it.
    if end_date.blank?
      others.where("start_date >= ? OR end_date IS NULL", start_date).exists?
    else
      others
        .where("start_date <= ?", end_date)
        .where("end_date IS NULL OR end_date >= ?", start_date)
        .exists?
    end
  end
end
