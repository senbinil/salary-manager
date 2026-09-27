require "rails_helper"

RSpec.describe EmployeeQuery do
  describe "#call" do
    let!(:engineering) { create(:department, name: "Engineering") }
    let!(:research) { create(:department, name: "Research") }
    let!(:engineer) { create(:designation, name: "Software Engineer") }
    let!(:scientist) { create(:designation, name: "Research Scientist") }

    it "returns all employees when no filters are supplied" do
      ada = create(:employee, name: "Ada Lovelace", department: engineering, designation: engineer)
      grace = create(:employee, name: "Grace Hopper", department: research, designation: scientist)

      expect(described_class.new({}).call).to contain_exactly(ada, grace)
    end

    it "matches the name case-insensitively and combines it with the id filters" do
      ada = create(:employee, name: "Ada Lovelace", department: engineering, designation: engineer)
      create(:employee, name: "Ada Byron", department: research, designation: engineer)
      create(:employee, name: "Grace Hopper", department: engineering, designation: scientist)

      results = described_class.new(
        "name_cont" => "ADA",
        "department_id" => engineering.id.to_s,
        "designation_id" => engineer.id.to_s
      ).call

      expect(results).to contain_exactly(ada)
    end

    it "filters active and inactive status based on a contract active today" do
      active = create(:employee, department: engineering, designation: engineer)
      expired = create(:employee, department: research, designation: scientist)
      future = create(:employee, department: research, designation: scientist)
      create(:employment_contract, employee: active, start_date: Date.current - 5.days)
      create(:employment_contract, employee: expired, start_date: Date.current - 20.days, end_date: Date.current - 1.day)
      create(:employment_contract, employee: future, start_date: Date.current + 1.day)

      expect(described_class.new("employment_status" => "active").call).to contain_exactly(active)
      expect(described_class.new("employment_status" => "inactive").call).to contain_exactly(expired, future)
    end

    it "filters the country code against the contract the status selects" do
      canada = create(:country, code: "CA", name: "Canada", currency: "CAD")
      united_states = create(:country, code: "US", name: "United States", currency: "USD")
      matching = create(:employee, department: engineering, designation: engineer)
      wrong_country = create(:employee, department: engineering, designation: engineer)
      old_only = create(:employee, department: engineering, designation: engineer)
      create(:employment_contract, employee: matching, country: canada, start_date: Date.current - 20.days)
      create(:employment_contract, employee: wrong_country, country: united_states, start_date: Date.current - 20.days)
      create(
        :employment_contract,
        employee: old_only,
        country: canada,
        start_date: Date.current - 400.days,
        end_date: Date.current - 300.days
      )

      expect(described_class.new("country_code" => "ca").call).to contain_exactly(matching, old_only)
      expect(described_class.new("country_code" => "CA", "employment_status" => "active").call).to contain_exactly(matching)
      expect(described_class.new("country_code" => "CA", "employment_status" => "inactive").call).to contain_exactly(old_only)
    end

    it "raises for an unsupported employment status" do
      expect { described_class.new("employment_status" => "pending").call }
        .to raise_error(described_class::InvalidFilter, /employment_status/)
    end

    it "raises for ids and country codes that are not valid" do
      expect { described_class.new("department_id" => "engineering").call }
        .to raise_error(described_class::InvalidFilter, /department_id must be an integer/)
      expect { described_class.new("designation_id" => "1.5").call }
        .to raise_error(described_class::InvalidFilter, /designation_id must be an integer/)
      expect { described_class.new("country_code" => "CAN").call }
        .to raise_error(described_class::InvalidFilter, /country_code must be a two-letter code/)
    end
  end
end
