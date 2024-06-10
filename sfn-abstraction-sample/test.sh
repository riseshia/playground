#!/bin/bash

set -eu

echo "Test merge 1 task"
jsonnet merge-one-task.jsonnet > merge-one-task-actual.json
ruby json_differ.rb merge-one-task-expected.json merge-one-task-actual.json
echo "  Passed"

echo "Test merge serial tasks"
jsonnet merge-serial-tasks.jsonnet > merge-serial-tasks-actual.json
ruby json_differ.rb merge-serial-tasks-expected.json merge-serial-tasks-actual.json
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
