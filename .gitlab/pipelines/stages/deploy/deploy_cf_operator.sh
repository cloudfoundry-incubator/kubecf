#!/usr/bin/env bash

set -o errexit

bazel run //dev/cf_operator:install_or_upgrade
