# frozen_string_literal: true

require_relative "./boot"

batch = Sidekiq::Batch.new
batch.description = "MRE: Batch + Iterable Interrupted"

batch.on(:complete, MreBatchCompleteCallback, {})

batch.jobs do
  MreIterableJob.perform_async(5)
end

puts "Enqueued batch bid=#{batch.bid}"
