#!/bin/bash

pid=$(cat process.pid)
# send sigkill
kill -9 $pid
