#!/usr/bin/env bash

set -o errexit -o nounset

bazel run //dev/linters/yamllint -- --config-file /dev/stdin --strict . <<'EOF'
    yaml-files:
    - "*.yaml"
    - "*.yml"
    ignore: |
        # Ignore gomplate templates
        *.tmpl.yaml
        *.tmpl.yml
        # Ignore helm templates
        /deploy/helm/kubecf/**/*
        # _don't_ ignore helm chart metadata
        !/deploy/helm/kubecf/*
    extends: relaxed
    rules:
        line-length:
            max: 120
EOF
