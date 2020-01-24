#!/bin/sh

# This script merges the two workspace status files into one.

set -o errexit

"{jq}" --slurp add "{info_file}" "{version_file}" > "{workspace_status}"
