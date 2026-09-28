require "rails_helper"

RSpec.describe SampleData::EmployeeSeeder do
  let(:null_logger) { Logger.new(File::NULL) }

  def seeder(count)
    described_class.new(count: count, logger: null_logger)
  end

  # Employees only, so a fixture created by an example cannot skew the names the
  # seeder generated.
  def created_names
    Employee.where.not(name: "Ada Lovelace").order(:id).pluck(:name)
  end

  it "creates the requested employees with distinct, plain names" do
    result = seeder(3).call

    expect(result).to eq(created: 3)
    expect(created_names.size).to eq(3)
    expect(created_names.uniq.size).to eq(3)
    # A first and last name, with no honorific or generational suffix: Faker's
    # Name.name occasionally adds "Gov." or "Jr.", which look wrong in a roster.
    expect(created_names).to all(match(/\A\S+ \S+\z/))
    expect(created_names.grep(/\./)).to be_empty
  end

  it "gives every employee one open contract and three components" do
    seeder(3).call

    expect(Employee.count).to eq(3)

    Employee.find_each do |employee|
      contract = employee.employment_contracts.sole
      expect(contract.end_date).to be_nil
      expect(contract.start_date).to be <= Date.current
      expect(contract.currency).to eq(contract.country.currency)

      compensation = contract.employee_compensation
      expect(compensation.compensation_plan).to be_present

      components = compensation.employee_compensation_components
      expect(components.size).to eq(3)
      expect(components.map(&:amount)).to all(be_positive)
    end
  end

  it "creates the reference data the dashboard needs when the instance has none" do
    seeder(1).call

    expect(Department.count).to eq(described_class::DEPARTMENTS.size)
    expect(Designation.count).to eq(described_class::DESIGNATIONS.size)
    expect(Country.count).to eq(described_class::COUNTRIES.size)
    expect(CompensationPlan.count).to eq(1)
    expect(SalaryComponent.count).to eq(described_class::SALARY_COMPONENTS.size)
  end

  # Loading is additive: without a marker there is nothing to identify a previous
  # load's rows by, so the seeder never deletes anything.
  it "adds to the roster rather than replacing it" do
    seeder(3).call
    result = seeder(2).call

    expect(result).to eq(created: 2)
    expect(Employee.count).to eq(5)
    expect(EmploymentContract.count).to eq(5)
    expect(EmployeeCompensation.count).to eq(5)
    expect(EmployeeCompensationComponent.count).to eq(15)
  end

  it "leaves an employee it did not create alone" do
    real_employee = create(:employee, name: "Ada Lovelace")

    seeder(2).call

    expect(real_employee.reload).to be_present
    expect(created_names.size).to eq(2)
    expect(Department.count).to be_positive
  end

  it "ends one contract in five, so both status filters have data" do
    seeder(5).call

    expect(EmploymentContract.where.not(end_date: nil).count).to eq(1)
    expect(EmploymentContract.where(end_date: nil).count).to eq(4)
  end

  # Counting from a fixed date would run past today at this volume and leave
  # every employee without a current contract.
  it "keeps every contract start date in the past, even at volume" do
    seeder(1_100).call

    expect(EmploymentContract.where("start_date > ?", Date.current).count).to eq(0)
    expect(EmploymentContract.where.not(end_date: nil).count).to eq(220)
  end

  it "refuses a count that is not positive" do
    expect { seeder(0).call }.to raise_error(ArgumentError, /positive/)
  end
end
