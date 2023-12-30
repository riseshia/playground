#!/bin/bash

set -e

export HOST=127.0.0.1
export PORT=3000
export PROCESS_COUNT=2
export RUBY_MAX_CPU=$PROCESS_COUNT

# servers="fiber" segfault with high traffic
servers="single_threaded multi_threaded prefork prefork_multi_threaded ractor"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <server>"
  echo "  <server> is one of $servers"
  exit 1
fi

server=$1

for worker_num in $(seq 4 4 32); do
  export WORKER_PER_PROCESS_COUNT=$worker_num

  echo "Benchmarking $server (process: $PROCESS_COUNT, worker per process: $WORKER_PER_PROCESS_COUNT)"
  export SERVER=$server

  bundle exec ruby start.rb &

  # wait boot up
  curl --silent --retry-connrefused --retry 10 --retry-delay 1 http://localhost:3000 > /dev/null

  k6 run load_test.js --summary-export "reports/${server}-${PROCESS_COUNT}-${WORKER_PER_PROCESS_COUNT}.json"

  ./kill_server.sh
done
