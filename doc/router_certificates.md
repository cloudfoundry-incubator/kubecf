# Router certificates

The default KubeCF installation generates a `router_ca` and a `router_ssl` variables. The former
is the CA certificate that signs the later, which in turn is used in the gorouter for TLS
termination.

For production systems, where certificates signed by a well-known Certificate Authority is required,
KubeCF allows those certificates to be passed via Helm properties. To do so, set the values:

```yaml
router:
  tls:
  - crt: |
      -----BEGIN CERTIFICATE-----
      ... cert_1
      -----END CERTIFICATE-----
    key: |
      -----BEGIN PRIVATE KEY-----
      ... cert_key_1
      -----END PRIVATE KEY-----
  - crt: |
      -----BEGIN CERTIFICATE-----
      ... cert_2
      -----END CERTIFICATE-----
    key: |
      -----BEGIN PRIVATE KEY-----
      ... cert_key_2
      -----END PRIVATE KEY-----
```

The certificates must be valid for `((system_domain))` and `*.((system_domain))`.
