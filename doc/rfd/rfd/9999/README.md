---
authors: Mark Yen <mark.yen@suse.com>
state: draft
discussion: https://github.com/cloudfoundry-incubator/kubecf/....
---

# RFD 9999 Vault Secret Management

## Motivation

We are moving towards using [Hashicorp Vault] for secrets management; however,
the details of such are yet to be hashed out.  This document is meant to align
the team on a unified design across our various consumers.

[Hashicorp Vault]: https://www.vaultproject.io/

## Requirements

We would like to get, out of this:

- The ability to rotate secrets (e.g. AWS access keys) and have the consumers
  automatically pick up the changes, so that we do not miss some consumer.
- Have [granular secrets] so that we could tell where each secret is used, so we
  can audit access.
- Disaster recovery: the credentials should be persistent enough that if the
  vault server dies, we can stand up a new instance with all the data intact.

[granular secrets]: https://github.com/cloudfoundry-incubator/kubecf/issues/1608

We have various consumers that require use of secrets, mostly in various CI
scenarios:

### Concourse pipelines

- Concourse has a built in [Vault credential manager].
- It only supports Vault's [K/V secrets engine version 1].  This means no
  versioning of secrets.
- It authenticates to Vault [from the web node]; this means that there's only
  one credential across the whole concourse instance.
  - As we run Concourse on Kubernetes, we should be able to use [vault-k8s] to
    inject the vault secrets.
- The secret path can be templated to include the (Concourse) team name,
  pipeline name, and secret name (all of which are optional).
- There also exists some [external resources] for Vault; due to API constraints,
  they would write out the secrets into a file instead.

[Vault credential manager]: https://concourse-ci.org/vault-credential-manager.html
[K/V secrets engine version 1]: https://www.vaultproject.io/api/secret/kv/kv-v1.html
[from the web node]: https://concourse-ci.org/vault-credential-manager.html#authenticating-with-vault
[vault-k8s]: https://github.com/hashicorp/vault-k8s
[external resources]: https://github.com/Comcast/concourse-vault-resource

### GitHub Actions

- There is a [first-party GitHub Action for Vault].
- It requires embedding the complete Vault secret path into the workflow.

[first-party GitHub Action for Vault]: https://github.com/hashicorp/vault-action

## Vault secret paths

Vault [does not support] any sort of symlink / alias functionality out of the box;
each secret only exists at one place.  This is an issue, since various pipelines
/ workflows are likely to have the same secret names pointing at different
things that only make sense for the particular installation (e.g. different AWS
credentials for various S3 buckets, different cloud provider credentials
depending on if the pipeline / workflow is for automated CI or development).

[does not support]: https://github.com/hashicorp/vault/issues/1284

Possibly solutions:
- A [proxy] in front of Vault to provide the alias capability.
  - This has the obvious issue that self-MITM has security implications.
  - It also functions as a translation layer so Concourse would be able to talk
    K/V version 1 to the proxy, which talks to the backend with K/V version 2.
- Duplicate secrets across the K/V store.
  - Syncing across the secrets will be an issue.
    - Can be mitigated somewhat with scripting.
      - Enforcing the use of scripts (i.e. no one-offs that skip it) will be
        difficult.
- We might consider writing out own [Vault plugin].
  - Additional engineering work that seems like a distraction.
  - Uncertain if the Vault plugin API supports impersonation.

[proxy]: https://github.com/Typositoire/go-vln
[Vault plugin]: https://learn.hashicorp.com/tutorials/vault/plugin-backends

## Best Practices

- All automation should be using [AppRole authentication]; this is basically
  OAuth style client ID / client secret authentication.  It ensures that the
  token we end up with will not expire prematurely.
- (Once we decide on how to work with the secret paths, we should add an entry
  here to document it.)

[AppRole authentication]: https://www.vaultproject.io/docs/auth/approle
