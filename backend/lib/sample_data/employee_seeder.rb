# Bulk sample employees for a production-like test instance: a load test at
# production scale, or a demo box.
#
# Loading is additive. Nothing written here carries a marker that could find it
# again, so there is no clear step: loading twice leaves two sets behind, and a
# clean roster means resetting the database.
#
# Volume is what makes this a batch job: 10k employees is roughly 60k rows once
# contracts, compensations and components are counted, so rows go in through
# insert_all in short transactions instead of one save! and one round trip per
# record. insert_all skips validations and callbacks, so the database
# constraints are the only safety net and every column a validation would have
# filled (currency, plan, amounts) is set explicitly here.
module SampleData
  class EmployeeSeeder
    BATCH_SIZE = 500

    # One employee in this many has a contract that already ended, so the
    # dashboard's active and inactive filters both have data at volume.
    #
    # Keep this coprime with the option counts below (10 countries, 5 departments,
    # 5 designations). Every dimension is indexed by the employee number, so a
    # period sharing a factor with an option count strands the inactive cohort on
    # a handful of options: at one in five, every inactive employee landed on
    # Australia or India and in a single department and designation, and neither
    # of those countries had an active employee at all.
    INACTIVE_EVERY = 3

    # Built from the two name lists rather than from Faker::Name.name, which
    # sometimes prefixes "Gov." or suffixes "Jr." - wrong for a payroll roster.
    # Each part is drawn fresh, so a name is retried until this run has not used
    # it. The `en` lists give roughly 140k combinations, so 10k employees need
    # almost no retries, and the cap turns a future shortage into a clear error
    # rather than a hang.
    NAME_ATTEMPTS = 50

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
      @used_names = {}
    end

    # Inserts count employees, numbered from one, and creates the reference data
    # they need when it is missing.
    def call
      raise ArgumentError, "count must be positive" unless count.positive?

      reference = ensure_reference_data
      logger.info "sample employees: creating #{count} in batches of #{BATCH_SIZE}"

      created = 0
      (1..count).each_slice(BATCH_SIZE) do |batch|
        create_batch(reference, batch)
        created += batch.size
        logger.info "sample employees: #{created}/#{count}"
      end

      { created: created }
    end

    private

    attr_reader :count, :logger

    def create_batch(reference, numbers)
      ActiveRecord::Base.transaction do
        employee_ids = insert_ids(Employee, numbers.map { |number|
          {
            name: unique_name,
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

    # A first and last name this run has not used yet.
    def unique_name
      NAME_ATTEMPTS.times do
        name = "#{Faker::Name.first_name} #{Faker::Name.last_name}"
        next if @used_names.key?(name)

        @used_names[name] = true
        return name
      end

      raise "sample employees: could not generate #{count} distinct names"
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
