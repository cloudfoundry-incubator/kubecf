#!/bin/sh

# This script converts the Bazel status input file to JSON so it can be consumed easily by other
# tools.

set -o errexit

"{jq}" \
  --raw-input \
  --slurp 'split("\n") | map(select(. != "")) | map(split(" ")) | map({(.[0]): .[1]}) | add' "{input}" \
  > "{output}"
