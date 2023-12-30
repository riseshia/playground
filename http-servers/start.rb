# frozen_string_literal: true

require_relative 'servers/ractor_server'
require_relative 'servers/fiber_server'
require_relative 'servers/single_threaded_server'
require_relative 'servers/multi_threaded_server'
require_relative 'servers/prefork_server'
require_relative 'servers/prefork_multi_threaded_server'

require_relative 'apps/cpu_heavy_app'
# require_relative 'apps/file_serving_app'
# require_relative 'apps/web_request_app'

app = {
  cpu_heavy: CpuHeavyApp,
# file_serving: FileServingApp,
# web_request: = WebRequestApp,
}.fetch(ENV.fetch('APP', 'cpu_heavy').to_sym)

server = {
  fiber: FiberServer,
  single_threaded: SingleThreadedServer,
  multi_threaded: MultiThreadedServer,
  prefork: PreforkServer,
  prefork_multi_threaded: PreforkMultiThreadedServer,
  ractor: RactorServer,
}.fetch(ENV.fetch('SERVER').to_sym)

server.new(app.new).start
