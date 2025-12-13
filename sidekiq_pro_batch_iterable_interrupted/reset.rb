# frozen_string_literal: true

require_relative "./boot"

Sidekiq.redis do |c|
  c.del(
    Mre::Keys::ABORT_ONCE,
    "queue:default",
    "retry",
  )
end

puts "Reset MRE keys"
