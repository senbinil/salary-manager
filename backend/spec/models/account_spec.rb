require "rails_helper"

RSpec.describe Account do
  # Account verification is disabled, so anything created outside Rodauth's
  # create-account endpoint (rails console, seeds, imports) must still end up
  # able to log in. The column default of 1 ("unverified") is a leftover from the
  # verify_account feature, and an unverified row is unreachable: login and
  # reset-password-request both refuse it, and no verification route exists.
  it "defaults new accounts to verified" do
    expect(described_class.new.status).to eq("verified")
  end

  # The default is a default, not a rule: Rodauth writes the status explicitly on
  # the create account path, and the factory sets its own, so those must survive.
  it "lets an explicit status win over the default" do
    expect(described_class.new(status: :unverified).status).to eq("unverified")
    expect(described_class.new(status: :closed).status).to eq("closed")
  end

  # Kept so legacy rows and the factory's :unverified trait still load.
  it "keeps the unverified status for legacy rows" do
    expect(described_class.statuses).to include("unverified" => 1)
  end

  # Role sits on the account, not the employee: access has to exist for accounts
  # with no employee record, because a user is not necessarily an employee. Least
  # privilege is the default.
  it "defaults new accounts to the least-privileged role" do
    expect(described_class.new.role).to eq("employee")
  end

  it "lets an explicit role win over the default" do
    expect(described_class.new(role: :hr).role).to eq("hr")
    expect(described_class.new(role: :manager).role).to eq("manager")
  end

  # The numbering is a security decision, not an accident: least privilege is the
  # low value, so anything that lands on 0 gets the fewest powers. Reordering
  # would silently hand out access, so pin the mapping.
  it "numbers the roles least-privileged first" do
    expect(described_class.roles).to eq("employee" => 0, "manager" => 1, "hr" => 2)
  end

  # Rodauth creates accounts through Sequel and never sees the model default, and
  # the public create-account route goes through it — so the column default is
  # what a self-signup actually gets. Insert the way Rodauth does and check it.
  it "defaults the role in the column as well as the model" do
    ActiveRecord::Base.connection.execute(
      "INSERT INTO accounts (email, status) VALUES ('raw-role@example.com', 2)"
    )

    expect(described_class.find_by(email: "raw-role@example.com").role).to eq("employee")
  end
end
