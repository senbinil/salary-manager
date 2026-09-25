require "rails_helper"

RSpec.describe EmploymentContract do
  let(:employee) { create(:employee) }

  it "defaults the currency to the country's" do
    contract = create(:employment_contract, country: create(:country, currency: "INR"), currency: nil)

    expect(contract.currency).to eq("INR")
  end

  # §3's expat case: employed in India, paid in USD. The country stays India for
  # reporting; only the currency the amounts are read in changes.
  it "lets a currency override the country's" do
    contract = create(:employment_contract, country: create(:country, currency: "INR"), currency: "USD")

    expect(contract.currency).to eq("USD")
  end

  it "requires an employee, a country, a plan, and a start date" do
    contract = build(
      :employment_contract,
      employee: nil,
      country: nil,
      compensation_plan: nil,
      start_date: nil
    )

    expect(contract).not_to be_valid
    expect(contract.errors[:employee]).to be_present
    expect(contract.errors[:country]).to be_present
    expect(contract.errors[:compensation_plan]).to be_present
    expect(contract.errors[:start_date]).to be_present
  end

  # The column is not null, so a blanked currency has to fail validation rather
  # than reach the database and come back as an exception.
  it "requires a currency" do
    contract = create(:employment_contract)
    contract.currency = nil

    expect(contract).not_to be_valid
    expect(contract.errors[:currency]).to be_present
  end

  # A null end_date is not a gap - it means still employed.
  it "allows an open-ended contract" do
    expect(build(:employment_contract, end_date: nil)).to be_valid
  end

  # The rule is end_date > start_date, so a contract cannot start and end on the
  # same day.
  it "rejects an end date that does not come after the start date" do
    contract = build(
      :employment_contract,
      start_date: Date.new(2026, 3, 1),
      end_date: Date.new(2026, 3, 1)
    )

    expect(contract).not_to be_valid
    expect(contract.errors[:end_date]).to be_present
  end

  describe "overlap" do
    # §7: one contract at a time, and ranges include their end date, so a
    # successor cannot start on the day its predecessor ends.
    it "rejects a contract that overlaps an existing one" do
      create(
        :employment_contract,
        employee: employee,
        start_date: Date.new(2026, 1, 1),
        end_date: Date.new(2026, 6, 30)
      )

      overlapping = build(
        :employment_contract,
        employee: employee,
        start_date: Date.new(2026, 6, 30),
        end_date: Date.new(2026, 12, 31)
      )

      expect(overlapping).not_to be_valid
      expect(overlapping.errors[:start_date]).to be_present
    end

    it "allows a contract that starts the day after another ends" do
      create(
        :employment_contract,
        employee: employee,
        start_date: Date.new(2026, 1, 1),
        end_date: Date.new(2026, 6, 30)
      )

      successor = build(:employment_contract, employee: employee, start_date: Date.new(2026, 7, 1))

      expect(successor).to be_valid
    end

    # An open-ended contract runs to infinity, so a second one always clashes -
    # whatever start date it carries.
    it "rejects a second open-ended contract" do
      create(:employment_contract, employee: employee, start_date: Date.new(2026, 1, 1))

      second = build(:employment_contract, employee: employee, start_date: Date.new(2026, 2, 1))

      expect(second).not_to be_valid
    end

    it "ignores another employee's contracts" do
      create(
        :employment_contract,
        employee: create(:employee),
        start_date: Date.new(2026, 1, 1),
        end_date: Date.new(2026, 12, 31)
      )

      expect(build(:employment_contract, employee: employee, start_date: Date.new(2026, 6, 1))).to be_valid
    end

    it "does not count a contract as overlapping itself" do
      contract = create(
        :employment_contract,
        employee: employee,
        start_date: Date.new(2026, 1, 1),
        end_date: Date.new(2026, 6, 30)
      )

      contract.end_date = Date.new(2026, 7, 31)

      expect(contract).to be_valid
    end
  end

  # The validation reads before it writes, so two concurrent inserts both pass
  # it. The partial unique index is what actually holds (§7), so insert the way a
  # racing request would and check the database refuses.
  it "holds one open-ended contract per employee in the database" do
    existing = create(:employment_contract)

    expect {
      insert_contract(
        employee_id: existing.employee_id,
        country_code: existing.country_code,
        compensation_plan_id: existing.compensation_plan_id,
        start_date: Date.new(2027, 1, 1)
      )
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  # Same idea for the date rule: the CHECK is the version of it that nothing can
  # skip. A non-null end_date keeps the partial index out of the way, so the
  # constraint under test is the only one this row can break.
  it "holds the end-after-start rule in the database" do
    existing = create(:employment_contract)

    expect {
      insert_contract(
        employee_id: existing.employee_id,
        country_code: existing.country_code,
        compensation_plan_id: existing.compensation_plan_id,
        start_date: Date.new(2028, 1, 1),
        end_date: Date.new(2028, 1, 1)
      )
    }.to raise_error(ActiveRecord::StatementInvalid, /employment_contracts_end_after_start/)
  end

  # Goes straight to the database, so a failure is the database's own rule rather
  # than the validation the examples above already cover.
  def insert_contract(employee_id:, country_code:, compensation_plan_id:, start_date:, end_date: nil)
    connection = ActiveRecord::Base.connection
    values = [
      employee_id,
      connection.quote(country_code),
      compensation_plan_id,
      connection.quote("USD"),
      connection.quote(start_date),
      end_date ? connection.quote(end_date) : "NULL"
    ].join(", ")

    connection.execute(
      "INSERT INTO employment_contracts " \
      "(employee_id, country_code, compensation_plan_id, currency, start_date, end_date) " \
      "VALUES (#{values})"
    )
  end
end
