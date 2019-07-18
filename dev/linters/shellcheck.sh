#!/usr/bin/env bash

set -o errexit

RED='\033[0;31m'
NC='\033[0m'

if ! hash shellcheck 2> /dev/null; then
  >&2 echo -e "${RED}shellcheck not installed${NC}"
  exit 1
fi

min_version="0.4.0"
current_version=$(shellcheck --version | awk '/^version:/{ print $2 }')

if [[ "$(echo -e "${min_version}\\n${current_version}" | sort -V | head -n 1)" != "${min_version}" ]]; then
  >&2 echo -e "${RED}minimum shellcheck version should be ${min_version}, found installed version ${current_version}${NC}"
  exit 1
fi

find . -name '*.sh' -print0 | xargs -0 -n1 shellcheck
