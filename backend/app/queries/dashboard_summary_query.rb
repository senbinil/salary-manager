# Builds the dashboard overview for the whole organization: how many employees
# are active today, and how they and their current compensation are distributed
# across the contract countries.
#
# Compensation is the sum of every component category on the current active
# contract, exactly as EmploymentContract#total_compensation defines it. The
# amounts stay in the contract's currency, so a country is labelled with its own
# currency rather than converted to a single base.
class DashboardSummaryQuery
  def call
    counts = active_contracts.group(:country_code).distinct.count(:employee_id)

    {
      total_active_employees: active_contracts.distinct.count(:employee_id),
      country_totals: country_totals(counts, compensation_totals)
    }
  end

  private

  # An employee is active when a contract includes today, both ends included and
  # a null end date running on - the same rule the employee roster uses.
  def active_contracts
    EmploymentContract.active
  end

  # The money lives on the components, one join away from the contract that
  # carries the country. Grouping by the contract keeps the country meaningful.
  def compensation_totals
    EmployeeCompensationComponent
      .joins(employee_compensation: :employment_contract)
      .merge(active_contracts)
      .group("employment_contracts.country_code")
      .sum(:amount)
  end

  # A country appears only when it has at least one active employee, and the rows
  # are ordered by code so the payload is stable for the client.
  def country_totals(counts, totals)
    countries = Country.where(code: counts.keys).index_by(&:code)

    counts.keys.sort.map do |code|
      country = countries.fetch(code)

      {
        country_code: code,
        country_name: country.name,
        currency: country.currency,
        employee_count: counts.fetch(code),
        total_compensation: totals.fetch(code, BigDecimal(0))
      }
    end
  end
end
