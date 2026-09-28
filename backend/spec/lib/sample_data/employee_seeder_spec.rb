require "rails_helper"

RSpec.describe SampleData::EmployeeSeeder do
  let(:null_logger) { Logger.new(File::NULL) }

  def seeder(count)
    described_class.new(count: count, logger: null_logger)
  end

  def sample_employees
    Employee.where("name LIKE ?", "#{described_class::NAME_PREFIX} %").order(:name)
  end

  def sample_names
    sample_employees.pluck(:name)
  end

  it "creates the requested employees, each with one open contract and three components" do
    seeder(3).call

    expect(sample_names).to eq([ "Sample Employee 00001", "Sample Employee 00002", "Sample Employee 00003" ])

    sample_employees.each do |employee|
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

  it "replaces the sample employees rather than adding to them" do
    seeder(3).call
    result = seeder(5).call

    expect(sample_names).to eq((1..5).map { |number| format("Sample Employee %05d", number) })
    expect(EmploymentContract.count).to eq(5)
    expect(EmployeeCompensation.count).to eq(5)
    expect(EmployeeCompensationComponent.count).to eq(15)
    expect(result).to eq(cleared: 3, created: 5)
  end

  it "clears only its own employees and leaves everything else alone" do
    real_employee = create(:employee, name: "Ada Lovelace")
    seeder(2).call
    sample_ids = sample_employees.pluck(:id)

    result = described_class.new(count: 0, logger: null_logger).clear

    expect(result).to eq(cleared: 2)
    expect(Employee.where(id: sample_ids)).to be_empty
    expect(EmploymentContract.where(employee_id: sample_ids)).to be_empty
    expect(EmployeeCompensation.count).to eq(0)
    expect(EmployeeCompensationComponent.count).to eq(0)
    expect(real_employee.reload).to be_present
    expect(Department.count).to be_positive
  end

  it "ends one contract in five, so both status filters have data" do
    seeder(5).call

    ended = EmploymentContract.where.not(end_date: nil).sole
    expect(Employee.find(ended.employee_id).name).to eq("Sample Employee 00005")
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
