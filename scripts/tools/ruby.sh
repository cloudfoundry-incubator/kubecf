# shellcheck shell=bash
# shellcheck disable=SC2034

TOOLS+=(ruby)

function ruby_version {
    ruby --version
}

RUBY_VERSION=2.4
