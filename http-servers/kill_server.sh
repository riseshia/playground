#!/bin/bash

pid=$(cat tmp/server.pid)
kill -s KILL $pid
