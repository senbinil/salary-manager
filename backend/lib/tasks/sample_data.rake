# Bulk sample data for a production-like test instance.
#
#   CONFIRM_SAMPLE_DATA=yes bin/rails sample_data:load[10000]
#   CONFIRM_SAMPLE_DATA=yes bin/rails sample_data:clear
#
# Both tasks demand the confirmation variable so neither fires by accident, and
# neither touches an employee SampleData::EmployeeSeeder did not create.
namespace :sample_data do
  confirm = lambda do
    abort "sample_data: refusing to run in the test environment" if Rails.env.test?
    abort "sample_data: set CONFIRM_SAMPLE_DATA=yes to confirm" unless ENV["CONFIRM_SAMPLE_DATA"] == "yes"
  end

  desc "Replace the sample employees with exactly COUNT, 10000 by default: sample_data:load[count]"
  task :load, [ :count ] => :environment do |_task, args|
    confirm.call

    count = (args[:count] || 10_000).to_i
    result = SampleData::EmployeeSeeder.new(count: count, logger: Logger.new($stdout)).call

    puts "sample employees: #{result[:created]} present (#{result[:cleared]} replaced)"
  end

  desc "Delete every sample employee with its contracts and compensation"
  task clear: :environment do
    confirm.call

    result = SampleData::EmployeeSeeder.new(logger: Logger.new($stdout)).clear

    puts "sample employees: #{result[:cleared]} removed"
  end
end
