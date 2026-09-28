# Bootstrap data for the sign-in accounts. This seed is idempotent, so it can be
# run again with `bin/rails db:seed`, and it runs in every environment - seeding
# the accounts is how a fresh instance gets its first login.
#
# The password comes from `credentials.default_password` and from nowhere else:
# this repository is public, so it must not carry a password of its own. The seed
# refuses to run without that credential, and warns before it writes in
# production.
#
# Neither reference data nor sample employees are seeded here - the dashboard
# wants thousands of employees for a load test, so both come from the
# sample_data task, which creates the reference data it needs on the way in:
#
#   CONFIRM_SAMPLE_DATA=yes bin/rails sample_data:load[10000]

if Rails.env.production?
  warn "WARNING: seeding sign-in accounts into production, with the password from credentials.default_password"
end

password = Rails.application.credentials.default_password
raise "credentials.default_password is not set - add it with `bin/rails credentials:edit`" if password.blank?

accounts = [
  { email: "dev@example.com", role: :employee },
  { email: "manager@example.com", role: :manager },
  { email: "hr@example.com", role: :hr }
]

accounts.each do |attributes|
  account = Account.find_or_initialize_by(email: attributes.fetch(:email))

  if account.new_record?
    account.password = password
    account.role = attributes.fetch(:role)
    account.save!
    puts "seeded account #{account.email} (#{account.role})"
  else
    puts "account #{account.email} already exists, leaving it alone"
  end
end
