# frozen_string_literal: false

worker_processes 8

listen 8080

timeout 300

after_request_complete do |_server, worker, _env|
  File.open("tmp/worker-#{worker.nr}", "a") do |f|
    f.puts "processed"
  end
end
