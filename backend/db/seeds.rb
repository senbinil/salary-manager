# Sample dashboard data for local development and test environments.
# This seed is idempotent, so it can be run again with `bin/rails db:seed`.

if Rails.env.development? || Rails.env.test?
  departments = %w[Engineering Finance Operations Product Sales].map do |name|
    Department.find_or_create_by!(name: name)
  end

  designations = ["Analyst", "Associate", "Engineer", "Manager", "Senior Engineer"].map do |name|
    Designation.find_or_create_by!(name: name)
  end

  1.upto(100) do |number|
    employee = Employee.find_or_initialize_by(name: format("Test Employee %03d", number))
    employee.department = departments[(number - 1) % departments.length]
    employee.designation = designations[(number - 1) % designations.length]
    employee.save!
  end
end
