#!/bin/bash

RUBY_DEBUG_LOG=stderr RUBY_MAX_CPU=2 ruby max_cpu_bug.rb 2>&1 | tee normal.log
RUBY_DEBUG_LOG=stderr RUBY_MAX_CPU=1 ruby max_cpu_bug.rb 2>&1 | tee debug.log
