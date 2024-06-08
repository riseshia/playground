#!/bin/bash

set -eu

echo "Test single task"
jsonnet single-task.jsonnet > single-task-actual.json
ruby json_differ.rb single-task-expected.json single-task-actual.json

# echo "Test fork tasks"
# jsonnet fork-tasks.jsonnet > fork-tasks-actual.json
# ruby json_differ.rb fork-tasks-expected.json fork-tasks-actual.json

# echo "Test complex tasks"
# jsonnet complex-tasks.jsonnet > complex-tasks-actual.json
# ruby json_differ.rb complex-tasks-expected.json complex-tasks-actual.json
