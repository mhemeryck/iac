# Goalkeepr database backups

The Goalkeepr PostgreSQL database is backed up daily to a private S3 bucket in `eu-central-1`.
The backup bucket retains archives for 90 days and applies 90-day Object Lock governance retention.
The backup CronJob can upload archives but cannot read or delete them.

## Deploy backups

### 1. Deploy AWS resources

Run Terraform from `envs/mhemeryck/aws-backups` using the authenticated AWS profile in the devenv shell.

```console
terraform init
terraform apply
```

Terraform stores the backup access key in its local state.
Do not commit, share, or copy that state outside the machine that administers this infrastructure.

### 2. Create the Kubernetes Secret

Extract the sensitive Terraform outputs and create the `goalkeepr-backup` Secret from `envs/mhemeryck/aws-backups` in Nushell.

```nu
let bucket = (terraform output -raw bucket_name); let access_key_id = (terraform output -raw access_key_id); let secret_access_key = (terraform output -raw secret_access_key); kubectl --namespace goalkeepr create secret generic goalkeepr-backup $"--from-literal=bucket=($bucket)" $"--from-literal=access_key_id=($access_key_id)" $"--from-literal=secret_access_key=($secret_access_key)" --dry-run=client --output=yaml | kubectl apply --filename=-
```

The Secret contains `bucket`, `access_key_id`, and `secret_access_key` keys in the `goalkeepr` namespace.

### 3. Deploy the Goalkeepr CronJob

Apply the Goalkeepr manifest from the IaC repository root after the Secret exists.

```console
kubectl apply --filename=goalkeepr.yaml
```

The CronJob runs daily at 02:00 UTC.

## Restore a backup

Download the required archive from the `goalkeepr/` S3 prefix using an AWS identity that can read the bucket.
Restore it into an isolated PostgreSQL database before considering a production restore.

```console
createdb goalkeepr-restore
pg_restore --clean --if-exists --no-owner --dbname=goalkeepr-restore backup.dump
```

Verify the restored Goalkeepr data before replacing any production data.
