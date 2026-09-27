# Builds the dashboard's employee relation from supported filter parameters.
# Each supplied filter is combined with the others, and the returned relation
# remains suitable for pagination and eager loading by the controller.
class EmployeeQuery
  FILTERS = %w[
    name_cont
    department_id
    designation_id
    employment_status
    country_code
  ].freeze

  class InvalidFilter < StandardError; end

  def initialize(filters)
    @filters = filters.to_h.stringify_keys.compact_blank
  end

  def call
    department_id = integer_filter("department_id")
    designation_id = integer_filter("designation_id")
    country_code = country_code_filter
    status = employment_status

    employees = name_filter(Employee.all)
    employees = employees.where(department_id: department_id) if department_id
    employees = employees.where(designation_id: designation_id) if designation_id
    employees = status_filter(employees, status)
    country_filter(employees, status, country_code)
  end

  private

  attr_reader :filters

  def name_filter(relation)
    value = filters["name_cont"]
    return relation if value.blank?

    relation.where("employees.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(value)}%")
  end

  def integer_filter(key)
    value = filters[key]
    return if value.blank?

    integer = Integer(value, exception: false)
    raise InvalidFilter, "#{key} must be an integer" if integer.nil?

    integer
  end

  def country_code_filter
    code = filters["country_code"]
    return if code.blank?
    raise InvalidFilter, "country_code must be a two-letter code" unless code.match?(/\A[A-Za-z]{2}\z/)

    code.upcase
  end

  def employment_status
    status = filters["employment_status"]
    return if status.blank?
    raise InvalidFilter, "employment_status must be active or inactive" unless %w[active inactive].include?(status)

    status
  end

  def status_filter(relation, status)
    return relation if status.nil?

    active_employee_ids = EmploymentContract.active.select(:employee_id)
    status == "active" ? relation.where(id: active_employee_ids) : relation.where.not(id: active_employee_ids)
  end

  # The country lives on the contract, so it follows the same status rule as
  # the status filter: an active employee is matched on the current contract,
  # an inactive one on an ended contract.
  def country_filter(relation, status, country_code)
    return relation if country_code.nil?

    relation.where(id: contracts_for_status(status).where(country_code: country_code).select(:employee_id))
  end

  def contracts_for_status(status)
    active_contracts = EmploymentContract.active
    ended_contracts = EmploymentContract.where("end_date < ?", Date.current)

    case status
    when "active"
      active_contracts
    when "inactive"
      ended_contracts
    else
      active_contracts.or(ended_contracts)
    end
  end
end
