#!/bin/bash

set -e

pid=$(cat tmp/server.pid)
kill -s TERM $pid

sleep 1
if ps -p $pid > /dev/null; then
  kill -s KILL $pid
fi
