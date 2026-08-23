# Goalkeepr database backups

The Goalkeepr PostgreSQL database is backed up daily to a private S3 bucket in `eu-central-1`.
The backup bucket retains archives for 90 days and applies 90-day Object Lock governance retention.
The backup CronJob can upload archives but cannot read or delete them.

## Provision AWS resources

Run Terraform from `envs/mhemeryck/aws-backups` using an authenticated local AWS profile.

```console
terraform init
terraform apply
```

Terraform stores the backup access key in its local state.
Do not commit, share, or copy that state outside the machine that administers this infrastructure.

Read the sensitive outputs and create the Kubernetes secret manually.

```console
terraform output -raw bucket_name
terraform output -raw access_key_id
terraform output -raw secret_access_key
```

The `goalkeepr-backup` secret must contain `bucket`, `access_key_id`, and `secret_access_key` keys in the `goalkeepr` namespace.
Apply `goalkeepr.yaml` only after this secret exists.

## Restore a backup

Download the required archive from the `goalkeepr/` S3 prefix using an AWS identity that can read the bucket.
Restore it into an isolated PostgreSQL database before considering a production restore.

```console
createdb goalkeepr-restore
pg_restore --clean --if-exists --no-owner --dbname=goalkeepr-restore backup.dump
```

Verify the restored Goalkeepr data before replacing any production data.
