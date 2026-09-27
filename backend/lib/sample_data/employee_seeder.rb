# Bulk sample employees for a production-like test instance: a load test at
# production scale, or a demo box.
#
# Everything it writes is marked by name (NAME_PREFIX), so #clear removes
# exactly what this class created and can never delete a real employee. Loading
# is clear-then-insert, which is what makes `load[N]` mean exactly N sample
# employees: every run leaves the same shape, at the cost of rewriting the set
# instead of topping it up.
#
# Volume is what makes this a batch job: 10k employees is roughly 60k rows once
# contracts, compensations and components are counted, so rows go in through
# insert_all in short transactions instead of one save! and one round trip per
# record. insert_all skips validations and callbacks, so the database
# constraints are the only safety net and every column a validation would have
# filled (currency, plan, amounts) is set explicitly here.
module SampleData
  class EmployeeSeeder
    NAME_PREFIX = "Sample Employee"
    BATCH_SIZE = 500

    # One employee in this many has a contract that already ended, so the
    # dashboard's active and inactive filters both have data at volume.
    INACTIVE_EVERY = 5

    DEPARTMENTS = %w[Engineering Finance Operations Product Sales].freeze
    DESIGNATIONS = [ "Analyst", "Associate", "Engineer", "Manager", "Senior Engineer" ].freeze
    COUNTRIES = [
      { code: "AU", name: "Australia", currency: "AUD" },
      { code: "BR", name: "Brazil", currency: "BRL" },
      { code: "CA", name: "Canada", currency: "CAD" },
      { code: "DE", name: "Germany", currency: "EUR" },
      { code: "GB", name: "United Kingdom", currency: "GBP" },
      { code: "IN", name: "India", currency: "INR" },
      { code: "JP", name: "Japan", currency: "JPY" },
      { code: "SG", name: "Singapore", currency: "SGD" },
      { code: "US", name: "United States", currency: "USD" },
      { code: "ZA", name: "South Africa", currency: "ZAR" }
    ].freeze
    PLAN_NAME = "Sample salary plan"

    # Employee number N gets base + N * step for each component, so the amounts
    # spread widely enough to make the dashboard's compensation filter usable.
    SALARY_COMPONENTS = [
      { name: "Base salary", category: :earning, base: 65_000, step: 250 },
      { name: "Housing allowance", category: :allowance, base: 12_000, step: 75 },
      { name: "Retirement contribution", category: :contribution, base: 6_000, step: 25 }
    ].freeze

    def initialize(count: 0, logger: Rails.logger)
      @count = count.to_i
      @logger = logger
    end

    # Replaces the sample employees with exactly count of them, numbered from
    # one, and creates the reference data they need when it is missing.
    def call
      raise ArgumentError, "count must be positive" unless count.positive?

      cleared = delete_sample_employees
      reference = ensure_reference_data
      logger.info "sample employees: replacing #{cleared} with #{count} in batches of #{BATCH_SIZE}"

      created = 0
      (1..count).each_slice(BATCH_SIZE) do |batch|
        create_batch(reference, batch)
        created += batch.size
        logger.info "sample employees: #{created}/#{count}"
      end

      { cleared: cleared, created: created }
    end

    # Removes every employee this class created, with its contracts,
    # compensations and components. Employees named any other way - and all
    # reference data - are left alone.
    def clear
      { cleared: delete_sample_employees }
    end

    private

    attr_reader :count, :logger

    def sample_employees
      Employee.where("name LIKE ?", "#{NAME_PREFIX} %")
    end

    def delete_sample_employees
      ids = sample_employees.pluck(:id)
      return 0 if ids.empty?

      logger.info "sample employees: removing #{ids.size}"
      ids.each_slice(BATCH_SIZE) do |slice|
        ActiveRecord::Base.transaction { delete_employees(slice) }
      end

      ids.size
    end

    def create_batch(reference, numbers)
      ActiveRecord::Base.transaction do
        employee_ids = insert_ids(Employee, numbers.map { |number|
          {
            name: format("#{NAME_PREFIX} %05d", number),
            department_id: pick(reference.fetch(:departments), number).id,
            designation_id: pick(reference.fetch(:designations), number).id
          }
        })

        contract_ids = insert_ids(EmploymentContract, numbers.each_with_index.map { |number, index|
          country = pick(reference.fetch(:countries), number)

          {
            employee_id: employee_ids.fetch(index),
            country_code: country.code,
            currency: country.currency,
            start_date: contract_start_date(number),
            end_date: contract_end_date(number)
          }
        })

        compensation_ids = insert_ids(EmployeeCompensation, contract_ids.map { |contract_id|
          { employment_contract_id: contract_id, compensation_plan_id: reference.fetch(:plan).id }
        })

        components = reference.fetch(:salary_components).each_with_index.map { |component, index|
          [ component, SALARY_COMPONENTS.fetch(index) ]
        }
        rows = compensation_ids.each_with_index.flat_map { |compensation_id, index|
          number = numbers.fetch(index)

          components.map { |component, attributes|
            {
              employee_compensation_id: compensation_id,
              salary_component_id: component.id,
              amount: attributes.fetch(:base) + number * attributes.fetch(:step)
            }
          }
        }
        EmployeeCompensationComponent.insert_all(rows)
      end
    end

    def delete_employees(ids)
      contract_ids = EmploymentContract.where(employee_id: ids).pluck(:id)
      compensation_ids = EmployeeCompensation.where(employment_contract_id: contract_ids).pluck(:id)

      EmployeeCompensationComponent.where(employee_compensation_id: compensation_ids).delete_all
      EmployeeCompensation.where(id: compensation_ids).delete_all
      EmploymentContract.where(id: contract_ids).delete_all
      Employee.where(id: ids).delete_all
    end

    # Spread over the last ten years rather than counted from a fixed date: an
    # offset added to a fixed date would push later contracts into the future.
    def contract_start_date(number)
      inactive?(number) ? Date.current - 800 : Date.current - (number % 3650)
    end

    def contract_end_date(number)
      return nil unless inactive?(number)

      Date.current - 100
    end

    def inactive?(number)
      (number % INACTIVE_EVERY).zero?
    end

    # Deterministic spread across the reference rows, so a given employee number
    # always lands on the same department, designation and country.
    def pick(records, number)
      records[number % records.size]
    end

    def insert_ids(model, rows)
      return [] if rows.empty?

      model.insert_all(rows, returning: :id).rows.flatten
    end

    def ensure_reference_data
      {
        departments: DEPARTMENTS.map { |name| Department.find_or_create_by!(name: name) },
        designations: DESIGNATIONS.map { |name| Designation.find_or_create_by!(name: name) },
        countries: COUNTRIES.map { |attributes| ensure_country(attributes) },
        plan: CompensationPlan.find_or_create_by!(name: PLAN_NAME),
        salary_components: SALARY_COMPONENTS.map { |attributes| ensure_salary_component(attributes) }
      }
    end

    def ensure_country(attributes)
      country = Country.find_or_initialize_by(code: attributes.fetch(:code))
      country.name = attributes.fetch(:name)
      country.currency = attributes.fetch(:currency)
      country.save!
      country
    end

    def ensure_salary_component(attributes)
      component = SalaryComponent.find_or_initialize_by(name: attributes.fetch(:name))
      component.category = attributes.fetch(:category)
      component.save!
      component
    end
  end
end
