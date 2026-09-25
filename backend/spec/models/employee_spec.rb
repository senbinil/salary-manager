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
end
