#!/usr/bin/env bash

set -o errexit -o nounset

exec bazel test //dev/linters:helm
