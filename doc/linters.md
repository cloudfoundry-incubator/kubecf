# Linters

The `make lint` targets runs tooling to statically check the
sources of kubecf.

The following linters are available:

  - `shellcheck.sh`:

    Runs shellcheck on all `.sh` files found in the entire checkout
    and reports any issues found.

  - `yamllint.sh`:

    Runs yamllint on all `.{yaml,yml}` files found in the entire checkout
    and reports any issues found.

  - `helmlint.sh`:

    Runs `helm lint` on the generated `kubecf` chart and repos any errors found.
