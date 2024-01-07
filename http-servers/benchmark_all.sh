#!/bin/bash

set -eu

export HOST=127.0.0.1
export PORT=3000
export PROCESS_COUNT=1
export MAX_PROCESS_NUM=5
export WORKER_PER_PROCESS_COUNT=1
export MAX_WORKER_NUM=64
# export APP=high_cpu
export APP=practical_usage

rm reports/*.json || true

# servers="fiber" segfault with high traffic
# servers="single_threaded multi_threaded prefork prefork_multi_threaded ractor"

# # single_threaded
# SERVER=single_threaded ./benchmark.sh
#
# # multi_threaded
for worker_num in $(seq 8 8 $MAX_WORKER_NUM); do
  # export WORKER_PER_PROCESS_COUNT=$worker_num
  export WORKER_PER_PROCESS_COUNT=64
  export RUBY_MN_THREADS=1
  export RUBY_MAX_CPU=3
  SERVER=multi_threaded ./benchmark.sh
  exit
done

# # prefork
# for process_num in $(seq 2 1 $MAX_PROCESS_NUM); do
#   export PROCESS_COUNT=$process_num
#   SERVER=prefork ./benchmark.sh
# done
#
# # prefork_multi_threaded
# for process_num in $(seq 1 1 $MAX_PROCESS_NUM); do
#   export PROCESS_COUNT=$process_num
#
#   for worker_num in $(seq 32 8 $MAX_WORKER_NUM); do
#     export WORKER_PER_PROCESS_COUNT=$worker_num
#     SERVER=prefork_multi_threaded ./benchmark.sh
#   done
# done

# # ractor
# for process_num in $(seq 1 1 $MAX_PROCESS_NUM); do
#   export PROCESS_COUNT=$process_num
#
#   for worker_num in $(seq 32 16 $MAX_WORKER_NUM); do
#     export WORKER_PER_PROCESS_COUNT=$worker_num
#     SERVER=ractor ./benchmark.sh
#   done
# done
