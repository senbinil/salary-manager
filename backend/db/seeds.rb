# Bootstrap data for a development or test instance: the accounts you sign in
# with. This seed is idempotent, so it can be run again with `bin/rails db:seed`.
#
# Neither reference data nor sample employees are seeded here - the dashboard
# wants thousands of employees for a load test, so both come from the
# sample_data task, which creates the reference data it needs on the way in:
#
#   CONFIRM_SAMPLE_DATA=yes bin/rails sample_data:load[10000]

if Rails.env.development? || Rails.env.test?
  accounts = [
    { email: "dev@example.com", password: "secret123", role: :employee },
    { email: "manager@example.com", password: "secret123", role: :manager },
    { email: "hr@example.com", password: "secret123", role: :hr }
  ]

  accounts.each do |attributes|
    account = Account.find_or_initialize_by(email: attributes.fetch(:email))

    if account.new_record?
      account.password = attributes.fetch(:password)
      account.role = attributes.fetch(:role)
      account.save!
      puts "seeded account #{account.email} (#{account.role})"
    else
      puts "account #{account.email} already exists, leaving it alone"
    end
  end
end
