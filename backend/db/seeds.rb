# Sample dashboard data for local development and test environments.
# This seed is idempotent, so it can be run again with `bin/rails db:seed`.

if Rails.env.development? || Rails.env.test?
  warn "WARNING: removing all employees, contracts, and compensation. Accounts and reference data are preserved."

  ActiveRecord::Base.transaction do
    EmployeeCompensationComponent.destroy_all
    EmployeeCompensation.destroy_all
    EmploymentContract.destroy_all
    Employee.destroy_all

    departments = %w[Engineering Finance Operations Product Sales].map do |name|
      Department.find_or_create_by!(name: name)
    end

    designations = [ "Analyst", "Associate", "Engineer", "Manager", "Senior Engineer" ].map do |name|
      Designation.find_or_create_by!(name: name)
    end

    countries = [
      { code: "CA", name: "Canada", currency: "CAD" },
      { code: "GB", name: "United Kingdom", currency: "GBP" },
      { code: "IN", name: "India", currency: "INR" },
      { code: "US", name: "United States", currency: "USD" }
    ].map do |attributes|
      country = Country.find_or_initialize_by(code: attributes.fetch(:code))
      country.name = attributes.fetch(:name)
      country.currency = attributes.fetch(:currency)
      country.save!
      country
    end

    compensation_plan = CompensationPlan.find_or_initialize_by(name: "Sample salary plan")
    compensation_plan.save!

    salary_components = [
      [ "Base salary", :earning ],
      [ "Housing allowance", :allowance ],
      [ "Retirement contribution", :contribution ]
    ].map do |name, category|
      salary_component = SalaryComponent.find_or_initialize_by(name: name)
      salary_component.category = category
      salary_component.save!
      salary_component
    end

    1.upto(100) do |number|
      employee = Employee.find_or_initialize_by(name: format("Test Employee %03d", number))
      employee.department = departments[(number - 1) % departments.length]
      employee.designation = designations[(number - 1) % designations.length]
      employee.save!

      country = countries[(number - 1) % countries.length]
      contract = employee.employment_contracts.find_or_initialize_by(end_date: nil)
      contract.country = country
      contract.currency = country.currency
      contract.start_date = Date.new(2024, 1, 1) + (number - 1)

      compensation = contract.employee_compensation || contract.build_employee_compensation
      compensation.compensation_plan = compensation_plan

      amounts = [ 65_000 + number * 250, 12_000 + number * 75, 6_000 + number * 25 ]
      salary_components.each_with_index do |salary_component, index|
        component = compensation.employee_compensation_components.find_or_initialize_by(
          salary_component: salary_component
        )
        component.amount = amounts.fetch(index)
      end

      contract.save!
    end
  end
end
