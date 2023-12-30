#!/bin/bash

set -eu
set -o pipefail

export HOST=127.0.0.1
export PORT=3000
export PROCESS_COUNT=${PROCESS_COUNT:-2}
export WORKER_PER_PROCESS_COUNT=${WORKER_PER_PROCESS_COUNT:-2}
export RUBY_MAX_CPU=$PROCESS_COUNT

echo
echo "----------------------------------------------------------------------------------------------------"
echo "Benchmarking ${SERVER} (process: ${PROCESS_COUNT}, worker per process: ${WORKER_PER_PROCESS_COUNT})"

bundle exec ruby start.rb &

# wait boot up
curl --silent --retry-connrefused --retry 10 --retry-delay 1 http://localhost:3000 > /dev/null

PC=$(printf "%02d" $PROCESS_COUNT)
WPRC=$(printf "%02d" $WORKER_PER_PROCESS_COUNT)
k6 run load_test.js --summary-export "reports/${SERVER}-${PC}-${WPRC}.json"

./kill_server.sh
