# Bulk sample data for a production-like test instance.
#
#   CONFIRM_SAMPLE_DATA=yes bin/rails sample_data:load[10000]
#
# The task demands the confirmation variable so it cannot fire by accident, and
# it refuses to run in the test environment. It only inserts: nothing identifies
# a previous load's rows, so loading twice leaves two sets behind.
namespace :sample_data do
  confirm = lambda do
    abort "sample_data: refusing to run in the test environment" if Rails.env.test?
    abort "sample_data: set CONFIRM_SAMPLE_DATA=yes to confirm" unless ENV["CONFIRM_SAMPLE_DATA"] == "yes"
  end

  desc "Create COUNT sample employees with generated names, 10000 by default: sample_data:load[count]"
  task :load, [ :count ] => :environment do |_task, args|
    confirm.call

    count = (args[:count] || 10_000).to_i
    result = SampleData::EmployeeSeeder.new(count: count, logger: Logger.new($stdout)).call

    puts "sample employees: #{result[:created]} created"
  end
end
