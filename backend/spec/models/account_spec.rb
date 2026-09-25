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
end
