#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools rspec

dirs=(
    chart/assets/scripts/
)

rspec "${dirs[@]}"
