require "rails_helper"

# Every other job spec calls `perform_now`; this one checks the queue wiring
# instead, by enqueuing through the Active Job adapter and having a real Solid
# Queue worker claim and run the job.
RSpec.describe "Processing FetchExchangeRateSnapshotsJob through Solid Queue" do
  # The worker runs the job on its own database connection, so it sees none of
  # this example's rows: the job finds no contracts and writes nothing, which
  # keeps the example inside the usual transaction. Only the queue rows are
  # committed, because they live in the separate queue database, and the after
  # hook below removes them.

  # The suite runs on the in-memory :test adapter; this example opts into the
  # adapter the app uses in every other environment.
  around do |example|
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :solid_queue
    example.run
  ensure
    ActiveJob::Base.queue_adapter = previous_adapter
  end

  let(:worker) do
    SolidQueue::Worker.new(
      queues: "default",
      threads: 1,
      polling_interval: 0.05
    ).tap do |worker|
      # Inline mode runs the supervisor loop in this thread and stops once no
      # ready executions are left, instead of polling until it is stopped.
      worker.mode = :inline
    end
  end

  # `perform` looks up the active contracts first, so this spy is what shows the
  # worker got into the job instead of only marking it finished.
  before { allow(EmploymentContract).to receive(:active).and_call_original }

  after do
    SolidQueue::Job.delete_all
    SolidQueue::Process.delete_all
  end

  it "enqueues through the adapter and runs the job on a worker" do
    active_job = FetchExchangeRateSnapshotsJob.perform_later

    queued_job = SolidQueue::Job.find(active_job.provider_job_id)
    expect(queued_job.class_name).to eq("FetchExchangeRateSnapshotsJob")
    expect(queued_job.queue_name).to eq("default")
    expect(queued_job).not_to be_finished

    worker.start

    expect(queued_job.reload).to be_finished
    expect(EmploymentContract).to have_received(:active)
    expect(SolidQueue::FailedExecution.count).to eq(0)
  end
end
