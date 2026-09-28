require "rails_helper"

RSpec.describe DashboardSummaryQuery do
  describe "#call" do
    it "reports no active employees and no countries when nothing is on record" do
      expect(described_class.new.call).to eq(
        total_active_employees: 0,
        country_totals: []
      )
    end

    it "counts only employees whose contract is active today" do
      india = create(:country, code: "IN", name: "India", currency: "INR")
      active = create(:employee)
      ended = create(:employee)
      future = create(:employee)
      create(:employment_contract, employee: active, country: india, start_date: Date.current - 5.days)
      create(
        :employment_contract,
        employee: ended,
        country: india,
        start_date: Date.current - 20.days,
        end_date: Date.current - 1.day
      )
      create(:employment_contract, employee: future, country: india, start_date: Date.current + 1.day)

      summary = described_class.new.call

      expect(summary[:total_active_employees]).to eq(1)
      expect(summary[:country_totals].map { |total| total[:employee_count] }).to eq([ 1 ])
    end

    it "groups active employees by their contract country and labels the country currency" do
      united_states = create(:country, code: "US", name: "United States", currency: "USD")
      canada = create(:country, code: "CA", name: "Canada", currency: "CAD")
      create(:employment_contract, employee: create(:employee), country: united_states, start_date: Date.current - 5.days)
      create(:employment_contract, employee: create(:employee), country: canada, start_date: Date.current - 5.days)
      create(:employment_contract, employee: create(:employee), country: canada, start_date: Date.current - 5.days)

      summary = described_class.new.call

      expect(summary[:total_active_employees]).to eq(3)
      expect(summary[:country_totals]).to eq([
        { country_code: "CA", country_name: "Canada", currency: "CAD",
          employee_count: 2, total_compensation: BigDecimal("10000") },
        { country_code: "US", country_name: "United States", currency: "USD",
          employee_count: 1, total_compensation: BigDecimal("5000") }
      ])
    end

    it "sums every component category on the active contract" do
      india = create(:country, code: "IN", name: "India", currency: "INR")
      contract = create(
        :employment_contract,
        employee: create(:employee),
        country: india,
        start_date: Date.current - 5.days
      )
      components = contract.employee_compensation.employee_compensation_components
      components.first.update!(amount: BigDecimal("10000.1250"))
      create(
        :employee_compensation_component,
        employee_compensation: contract.employee_compensation,
        salary_component: create(:salary_component, category: :allowance),
        amount: BigDecimal("250.2500")
      )
      create(
        :employee_compensation_component,
        employee_compensation: contract.employee_compensation,
        salary_component: create(:salary_component, category: :contribution),
        amount: BigDecimal("100.0000")
      )

      summary = described_class.new.call

      expect(summary[:country_totals].first[:total_compensation]).to eq(BigDecimal("10350.375"))
    end

    it "excludes compensation from contracts that are not active today" do
      india = create(:country, code: "IN", name: "India", currency: "INR")
      expired = create(:employee)
      create(
        :employment_contract,
        employee: expired,
        country: india,
        start_date: Date.current - 20.days,
        end_date: Date.current - 1.day
      )

      summary = described_class.new.call

      expect(summary[:total_active_employees]).to eq(0)
      expect(summary[:country_totals]).to eq([])
    end

    it "orders countries by code" do
      canada = create(:country, code: "CA", name: "Canada", currency: "CAD")
      japan = create(:country, code: "JP", name: "Japan", currency: "JPY")
      create(:employment_contract, employee: create(:employee), country: japan, start_date: Date.current - 5.days)
      create(:employment_contract, employee: create(:employee), country: canada, start_date: Date.current - 5.days)

      summary = described_class.new.call

      expect(summary[:country_totals].map { |total| total[:country_code] }).to eq(%w[CA JP])
    end
  end
end
