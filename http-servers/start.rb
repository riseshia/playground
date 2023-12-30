# frozen_string_literal: true

require_relative 'servers/ractor_server'
require_relative 'servers/fiber_server'
require_relative 'servers/single_threaded_server'
require_relative 'servers/multi_threaded_server'
require_relative 'servers/prefork_server'
require_relative 'servers/prefork_multi_threaded_server'

require_relative 'apps/practical_usage_app'

app = {
  practical_usage: PracticalUsageApp,
}.fetch(ENV.fetch('APP', 'practical_usage').to_sym)

server = {
  fiber: FiberServer,
  single_threaded: SingleThreadedServer,
  multi_threaded: MultiThreadedServer,
  prefork: PreforkServer,
  prefork_multi_threaded: PreforkMultiThreadedServer,
  ractor: RactorServer,
}.fetch(ENV.fetch('SERVER').to_sym)

server.new(app.new).start
