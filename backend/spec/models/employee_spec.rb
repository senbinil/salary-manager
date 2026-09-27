require "rails_helper"

RSpec.describe Employee do
  it "requires a name" do
    employee = build(:employee, name: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:name]).to be_present
  end

  it "requires a department and a designation" do
    employee = build(:employee, department: nil, designation: nil)

    expect(employee).not_to be_valid
    expect(employee.errors[:department]).to be_present
    expect(employee.errors[:designation]).to be_present
  end

  # A user is not necessarily an employee, and most employees never sign in, so
  # the link to an account is optional.
  it "can exist with no account behind it" do
    expect(build(:employee, user: nil)).to be_valid
  end

  # The link is one-to-one, so a second employee cannot claim an account that is
  # already linked.
  it "holds at most one employee per account" do
    account = create(:account, :verified)
    create(:employee, user: account)

    expect(build(:employee, user: account)).not_to be_valid
  end

  it "resolves the account behind it" do
    account = create(:account, :verified)

    expect(create(:employee, user: account).user).to eq(account)
  end

  describe "#total_compensation" do
    it "sums every component on the current active contract only" do
      employee = create(:employee)
      create(
        :employment_contract,
        employee: employee,
        start_date: Date.current - 60,
        end_date: Date.current - 11
      )
      active_contract = create(
        :employment_contract,
        employee: employee,
        start_date: Date.current - 10,
        end_date: Date.current + 10
      )
      create(
        :employment_contract,
        employee: employee,
        start_date: Date.current + 11,
        end_date: nil
      )

      components = active_contract.employee_compensation.employee_compensation_components
      components.first.update!(amount: BigDecimal("10000.1250"))
      create(
        :employee_compensation_component,
        employee_compensation: active_contract.employee_compensation,
        salary_component: create(:salary_component, category: :allowance),
        amount: BigDecimal("250.2500")
      )
      create(
        :employee_compensation_component,
        employee_compensation: active_contract.employee_compensation,
        salary_component: create(:salary_component, category: :contribution),
        amount: BigDecimal("500.1000")
      )

      expect(employee.total_compensation).to eq(BigDecimal("10750.4750"))
    end

    it "returns nil when the employee has no active contract" do
      employee = create(:employee)
      create(
        :employment_contract,
        employee: employee,
        start_date: Date.current - 60,
        end_date: Date.current - 11
      )
      create(
        :employment_contract,
        employee: employee,
        start_date: Date.current + 1,
        end_date: nil
      )

      expect(employee.total_compensation).to be_nil
    end
  end

  describe "employment contracts" do
    it "returns this employee's contracts across their history" do
      employee = create(:employee)
      other_employee = create(:employee)
      first_contract = create(
        :employment_contract,
        employee: employee,
        start_date: Date.new(2026, 1, 1),
        end_date: Date.new(2026, 6, 30)
      )
      second_contract = create(
        :employment_contract,
        employee: employee,
        start_date: Date.new(2026, 7, 1),
        end_date: Date.new(2026, 12, 31)
      )
      other_contract = create(:employment_contract, employee: other_employee)

      expect(employee.employment_contracts).to contain_exactly(first_contract, second_contract)
      expect(other_contract.employee).to eq(other_employee)
    end
  end
end
