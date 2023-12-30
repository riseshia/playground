#!/bin/bash

set -e

export HOST=127.0.0.1
export PORT=3000
export PROCESS_COUNT=2
export WORKER_PER_PROCESS_COUNT=2
export RUBY_MAX_CPU=$PROCESS_COUNT

servers="fiber single_threaded multi_threaded prefork prefork_multi_threaded ractor"
# servers="fiber" segfault with high traffic
servers="single_threaded multi_threaded prefork prefork_multi_threaded ractor"

for server in $servers; do
  echo "Benchmarking $server"
  export SERVER=$server

  bundle exec ruby start.rb &

  # wait boot up
  curl --silent --retry-connrefused --retry 10 --retry-delay 1 http://localhost:3000 > /dev/null

  k6 run load_test.js --summary-export "reports/${server}.json"

  ./kill_server.sh
done
