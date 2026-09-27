require "rails_helper"

# The seed runs inside the example's transaction, so nothing it writes outlives
# the example.
RSpec.describe "db/seeds.rb" do
  subject(:run_seed) { load Rails.root.join("db/seeds.rb") }

  it "creates the sign-in accounts with their roles, verified" do
    run_seed

    expect(Account.order(:email).pluck(:email, :role)).to eq([
      [ "dev@example.com", "employee" ],
      [ "hr@example.com", "hr" ],
      [ "manager@example.com", "manager" ]
    ])
    expect(Account.pluck(:status).uniq).to eq([ "verified" ])
  end

  # db:seed:replant runs the seed against the test database in CI, so anything
  # it creates here is still there for the next suite run. Employees belong to
  # the sample_data task, which is explicit about what it replaces.
  it "seeds no employees or reference data, because the sample_data task owns those" do
    run_seed

    expect(Employee.count).to eq(0)
    expect(EmploymentContract.count).to eq(0)
    expect(Department.count).to eq(0)
    expect(Country.count).to eq(0)
  end

  it "leaves an account it already created alone when run again" do
    run_seed

    expect { run_seed }.not_to change { Account.order(:email).pluck(:email, :role, :password_hash) }
  end
end
