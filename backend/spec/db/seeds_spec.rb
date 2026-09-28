require "rails_helper"

# The seed runs inside the example's transaction, so nothing it writes outlives
# the example.
RSpec.describe "db/seeds.rb" do
  subject(:run_seed) { load Rails.root.join("db/seeds.rb") }

  let(:credentials) { double(default_password: "from-credentials") }

  before do
    # db:seed:replant runs this seed against the test database in CI, so the
    # accounts may already be here; every example starts from a clean slate.
    Account.delete_all
    allow(Rails.application).to receive(:credentials).and_return(credentials)
  end

  it "creates the sign-in accounts with their roles, verified" do
    run_seed

    expect(Account.order(:email).pluck(:email, :role)).to eq([
      [ "dev@example.com", "employee" ],
      [ "hr@example.com", "hr" ],
      [ "manager@example.com", "manager" ]
    ])
    expect(Account.pluck(:status).uniq).to eq([ "verified" ])
  end

  # The repository is public, so the seed must never carry a password of its own.
  it "takes the password from credentials.default_password" do
    run_seed

    expect(Account.all).to all(
      satisfy { |account| BCrypt::Password.new(account.password_hash) == "from-credentials" }
    )
  end

  it "refuses to seed when credentials.default_password is missing" do
    allow(credentials).to receive(:default_password).and_return(nil)

    expect { run_seed }.to raise_error(/default_password/)
    expect(Account.count).to eq(0)
  end

  # db:seed:replant runs the seed against the test database in CI, so anything
  # it creates here is still there for the next suite run. Employees belong to
  # the sample_data task, which the operator runs deliberately.
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

  # Production gets the accounts too - it is how a fresh instance gets its first
  # login - but it says so first.
  context "in production" do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production"))
    end

    it "warns before it writes, and still uses the credentials password" do
      expect { run_seed }.to output(/WARNING: seeding sign-in accounts into production/).to_stderr

      expect(Account.count).to eq(3)
      expect(Account.all).to all(
        satisfy { |account| BCrypt::Password.new(account.password_hash) == "from-credentials" }
      )
    end

    it "refuses to seed when credentials.default_password is missing" do
      allow(credentials).to receive(:default_password).and_return(nil)

      expect { run_seed }.to raise_error(/default_password/)
      expect(Account.count).to eq(0)
    end
  end
end
