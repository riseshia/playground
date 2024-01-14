#!/bin/bash

set -eu
set -o pipefail

export HOST=127.0.0.1
export PORT=3000
export PROCESS_COUNT=3
export WORKER_PER_PROCESS_COUNT=64
export RUBY_MAX_CPU=$PROCESS_COUNT
export APP=practical_usage
export SERVER=ractor

echo
echo "----------------------------------------------------------------------------------------------------"
echo "Benchmarking ${APP} on ${SERVER} (process: ${PROCESS_COUNT}, worker per process: ${WORKER_PER_PROCESS_COUNT})"


if lsof -i :$PORT > /dev/null; then
  echo "Port $PORT is open. can't start."
  exit 1
fi

# bundle exec ruby start.rb
export RUBY_DEBUG_LOG=stderr
bundle exec ruby start.rb 2>&1 | tee debug.log
