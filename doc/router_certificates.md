# Router certificates

The default KubeCF installation generates the `router_ca` and `router_ssl` variables. The former
is the CA certificate that signs the latter, which in turn is used in the gorouter for TLS
termination.

For production systems, where certificates signed by a well-known certificate authority is required,
KubeCF allows those certificates to be passed via Helm properties. To do so, set the values:

```yaml
settings:
  router:
    tls:
      crt: |
        -----BEGIN CERTIFICATE-----
        ...
        -----END CERTIFICATE-----
      key: |
        -----BEGIN PRIVATE KEY-----
        ...
        -----END PRIVATE KEY-----
```

The certificates must be valid for `((system_domain))` and `*.((system_domain))`.

For production systems using TLS certificates signed by an internal certificate authority, the `ca`
property can also be set under `tls`. To do so, set the values:

```yaml
settings:
  router:
    tls:
      ca: |
        -----BEGIN CERTIFICATE-----
        ...
        -----END CERTIFICATE-----
      crt: |
        -----BEGIN CERTIFICATE-----
        ...
        -----END CERTIFICATE-----
      key: |
        -----BEGIN PRIVATE KEY-----
        ...
        -----END PRIVATE KEY-----
```
