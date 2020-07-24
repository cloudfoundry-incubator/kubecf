#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools ruby

ruby src/kubecf-tools/versioning/versioning.rb
