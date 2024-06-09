#!/bin/bash

set -eu

echo "Test compile 1 task"
jsonnet compile-one-task.jsonnet > compile-one-task-actual.json
ruby json_differ.rb compile-one-task-expected.json compile-one-task-actual.json
echo "  Passed"

echo "Test compile serial tasks"
jsonnet compile-serial-tasks.jsonnet > compile-serial-tasks-actual.json
ruby json_differ.rb compile-serial-tasks-expected.json compile-serial-tasks-actual.json
echo "  Passed"

echo "Test single task"
jsonnet single-task.jsonnet > single-task-actual.json
ruby json_differ.rb single-task-expected.json single-task-actual.json
echo "  Passed"

echo "Test two tasks"
jsonnet two-tasks.jsonnet > two-tasks-actual.json
ruby json_differ.rb two-tasks-expected.json two-tasks-actual.json
echo "  Passed"

echo "Test fork tasks"
jsonnet fork-tasks.jsonnet > fork-tasks-actual.json
ruby json_differ.rb fork-tasks-expected.json fork-tasks-actual.json
echo "  Passed"

echo "Test complex tasks"
jsonnet complex-tasks.jsonnet > complex-tasks-actual.json
ruby json_differ.rb complex-tasks-expected.json complex-tasks-actual.json
echo "  Passed"
