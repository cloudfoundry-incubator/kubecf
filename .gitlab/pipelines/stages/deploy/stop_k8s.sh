#!/usr/bin/env bash

set -o errexit -o nounset

ps ax | awk '/[k]3s server/{ print $1 }' | xargs --max-line=1 --no-run-if-empty sudo kill
