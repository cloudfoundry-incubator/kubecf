# CCDB encryption key rotation

**IMPORTANT** - Always backup the database before rotating the encryption key.

The key used to encrypt the database is generated the first time kubecf is deployed.
It is based on the Helm values:

```yaml
ccdb:
  encryption:
    rotation:
      key_labels:
      - encryption_key_0
      current_key_label: encryption_key_0
```

For each label under `key_labels`, kubecf will generate an encryption key.
The `current_key_label` indicates which key is currently being used.

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
kubectl patch qjob rotate-cc-database-key \
  --namespace kubecf \
  --type merge \
  --patch '{"spec":{"trigger":{"strategy":"now"}}}'
```

## Importing encryption keys

When you import a CCDB database (e.g. via `mysqldump`), then the corresponding encryption
keys must be imported as well so that the data can be decrypted by the cloud controller.

If the exported data has never had its encryption key rotated, then the only thing to set is
the top level (legacy) encryption key:

```yaml
credentials:
  cc_db_encryption_key: "initial-encryption-key"
```

After the data has been rotated, all the key labels and values need to be set like this:

```yaml
ccdb:
  encryption:
    rotation:
      key_labels:
      - NEW_KEY
      current_key_label: NEW_KEY

credentials:
  cc_db_encryption_key: "initial-encryption-key"
  ccdb_key_label_new_key: "new-encryption-key"
```

The `key_labels` must be defined **exactly** as they were set in the exporting installation.
As long as the actual key rotation has been performed after the last change to the
`current_key_label`, only the current key label and value need to be configured.

Their values are stored under credential keys that are made from the lowercase version of
their key names, prefixed with `ccdb_key_label_`.

All key names must conform to this regexp: `"^[a-zA-Z]+[a-zA-Z0-9_]*[a-zA-Z0-9]+$"`.
If it doesn't, then the CCDB must be rotated to a conforming key name **before** the
data is exported.
