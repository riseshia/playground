#!/bin/bash

set -eu

jsonnet schedule.jsonnet > actual.json

ruby json_differ.rb expected.json actual.json
