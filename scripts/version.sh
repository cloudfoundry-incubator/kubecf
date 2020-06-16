#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools git

echo "v0.0.0-$(git rev-parse --short HEAD)"
