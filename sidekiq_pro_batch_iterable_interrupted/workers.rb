# frozen_string_literal: true

require "sidekiq"
require "sidekiq/batch"
require "sidekiq/job/iterable"

module Mre
  module Keys
    ABORT_ONCE = "mre:iterable:abort_once"
  end
end

class MreBatchCompleteCallback
  # Sidekiq Pro Batch callbacks call `#on_complete(status, options)`.
  def on_complete(status, _options)
    Sidekiq.logger.warn("[MRE] BATCH COMPLETE callback fired (bid=#{status.bid})")
  end
end

# This is a real Iterable job (Sidekiq 7.3+) which will intentionally interrupt once.
#
# Behavior:
# - On the first execution it stops early via `throw(:abort, false)`.
#   Sidekiq then re-enqueues the job by raising Sidekiq::Job::Interrupted.
# - On the next execution it finishes all iterations.
#
# The bug under report: when used inside Sidekiq Pro Batch, the first
# Interrupted is treated as a normal failure by Batch::Server middleware,
# which can trigger :complete early if pending hits 0.
class MreIterableJob
  include Sidekiq::IterableJob

  sidekiq_options queue: "default", retry: false

  def build_enumerator(total, cursor:)
    array = (0...Integer(total)).to_a
    cursor_offset = cursor.nil? ? nil : Integer(cursor)
    array_enumerator(array, cursor: cursor_offset)
  end

  def each_iteration(item, total)
    # Force a single interruption on the first run.
    aborted_now = Sidekiq.redis { |c| c.set(Mre::Keys::ABORT_ONCE, "1", nx: true) }
    if aborted_now
      Sidekiq.logger.warn("[MRE] Forcing early abort to trigger Interrupted (item=#{item})")
      throw :abort, false
    end

    # Slow down so it's easier to see ordering in logs
    sleep 0.2

    Sidekiq.logger.info("[MRE] Processed item=#{item} / total=#{total}")
  end
end
