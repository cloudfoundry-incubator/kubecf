#!/usr/bin/env bash

set -o errexit

bazel run //dev/cf_operator:apply
