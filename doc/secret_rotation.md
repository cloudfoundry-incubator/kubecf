# Secret rotation

## CCDB encryption key

**IMPORTANT** - Always backup the database before rotating the encryption key.

The key used to encrypt the database is generated the first time kubecf is deployed. It is based on
the Helm values:

```yaml
ccdb:
  encryption:
    rotation:
      key_labels:
      - encryption_key_0
      current_key_label: encryption_key_0
```

For each label under `key_labels`, kubecf will generate an encryption key. The `current_key_label`
indicates which key is currently being used.

In order to rotate the CCDB encryption key, add a new label to `key_labels` (keeping the old
labels), and mark the `current_key_label` with the newly added label. Example:

```yaml
ccdb:
  encryption:
    rotation:
      key_labels:
      - encryption_key_0
      - encryption_key_1
      current_key_label: encryption_key_1
```

**IMPORTANT** - key labels should be less than 240 characters long.

Then, update the kubecf Helm installation. After Helm finishes its updates, trigger the
`rotate-cc-database-key` errand:

**Note** - the following command assumes the Helm installation is named `kubecf` and it was
installed to the `kubecf` namespace. These values may be different depending on how kubecf was
installed.

```sh
kubectl patch qjob kubecf-rotate-cc-database-key \
  --namespace kubecf \
  --type merge \
  --patch '{"spec":{"trigger":{"strategy":"now"}}}'
```
