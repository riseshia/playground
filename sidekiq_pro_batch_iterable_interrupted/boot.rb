# frozen_string_literal: true

require "bundler/setup"
require "logger"
require "sidekiq"
require "sidekiq-pro"
require "sidekiq/batch"
require "sidekiq/job/iterable"
require_relative "./workers"

REDIS_URL = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_client do |config|
  config.redis = { url: REDIS_URL }
end

Sidekiq.configure_server do |config|
  config.redis = { url: REDIS_URL }

  # Make logs easy to read in the reproduction
  config.logger.level = Logger::DEBUG
end
