#!/bin/sh

# This script merges the two workspace status files into one.

set -o errexit

echo "$(cat "{info_file}") $(cat "{version_file}")" | "{jq}" --slurp add > "{workspace_status}"
