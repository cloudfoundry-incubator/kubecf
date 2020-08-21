#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools helm perl

TEST_DIR="${TEMP_DIR}/test"

[ -d "${TEST_DIR}" ] && rm -rf "${TEST_DIR}"
mkdir -p "${TEST_DIR}"

cp -a tests/config/* "${TEST_DIR}"
cp chart/templates/_*.tpl "${TEST_DIR}/templates"

HELM_ARGS=(
    --set "helm_nil=null"
    --set 'helm_empty='
    --set "helm_zero=0"
    --set "helm_one=1"
    --set "helm_true=true"
    --set "helm_false=false"
)

if [ -n "${NO_FAIL:-}" ]; then
    helm template "${TEST_DIR}" --set fail_on_error=false "${HELM_ARGS[@]}" "$@"
else
    # Discard all output from stdout, in case the test succeeds.
    # Discard all lines from stderr, except for the message from {{ fail $message }}.
    helm template "${TEST_DIR}" "${HELM_ARGS[@]}" "$@" >/dev/null \
         2> >(perl -ne 'print if s/.*error calling fail: //' >&2)
fi
