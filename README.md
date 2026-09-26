# Infrastructure

## What?

Personal infrastructure for [mhemeryck.xyz](https://mhemeryck.xyz)
Hetzner k3s, DNS, self-hosted services, AWS state and backup storage
Terraform for most resources; Kubernetes manifests for the rest

## Structure

Terraform modules in top-level directories such as `node/`, `wekan/` and `vaultwarden/`
Instantiations in `envs/mhemeryck/<module>/`, each with its own S3 state key
Shared state bucket from `state-backend/`; manually managed Kubernetes resources in root-level YAML
Shared backup storage module in `backup-storage/`; separate buckets and upload identities per service

## Quickstart: devenv

Devenv for Terraform, AWS CLI, SecretSpec and `pass`
Hetzner token and kubeconfig via SecretSpec; AWS profile `mhemeryck`
Shared Terraform provider cache at `~/.cache/terraform/plugin-cache`

Example, Wekan root:

    devenv shell
    cd envs/mhemeryck/wekan
    terraform init
    terraform plan
    terraform apply

Other roots: same commands from the matching `envs/mhemeryck/` directory

## Modules

### node

Hetzner server, firewall, k3s and DNS
Root: `envs/mhemeryck/node/`
Kubeconfig: SecretSpec `pass` entry `secretspec/iac/default/KUBECONFIG`

### state-backend

Shared, versioned S3 bucket for Terraform state
Root: `envs/mhemeryck/state-backend/`
S3 lockfiles; one state key per root

### github-actions

AWS OIDC provider and `home-github-actions` role
Root: `envs/mhemeryck/github-actions/`
Administrator access for trusted `master` workflows

### wekan

Planning board and MongoDB in the `wekan` namespace
Root: `envs/mhemeryck/wekan/`
Daily MongoDB backups at 02:00 cluster time; 90-day Object Lock retention in `wekan-backups-<account-id>/wekan/`

On-demand backup:

    kubectl create job -n wekan --from=cronjob/mongodb-backup mongodb-backup-manual
    kubectl wait -n wekan --for=condition=complete job/mongodb-backup-manual --timeout=10m
    kubectl logs -n wekan job/mongodb-backup-manual -c upload
    aws s3 ls "s3://wekan-backups-$(aws sts get-caller-identity --query Account --output text)/wekan/"

Restore check; isolated MongoDB, AWS identity with bucket read access:

    bucket="wekan-backups-$(aws sts get-caller-identity --query Account --output text)"
    aws s3 cp "s3://$bucket/wekan/TIMESTAMP.archive.gz" wekan.archive.gz
    docker run -d --rm --name wekan-restore mongo:6.0.26-jammy
    docker cp wekan.archive.gz wekan-restore:/tmp/wekan.archive.gz
    docker exec wekan-restore mongorestore --gzip --archive=/tmp/wekan.archive.gz --nsInclude='wekan.*'
    docker exec wekan-restore mongosh --quiet --eval 'db.getSiblingDB("wekan").getCollectionNames()'
    docker stop wekan-restore

### vaultwarden

Password manager and Postgres in the existing `bitwarden` namespace
Root: `envs/mhemeryck/vaultwarden/`
Imported Secrets and data PVCs; password-derived Postgres DSN; TLS via cert-manager
Credentials in S3-backed Terraform state; no local `secrets.yaml` dependency
Daily backup at 03:00 cluster time: Postgres dump and `/data` in one archive
S3: `vaultwarden-backups-<account-id>/vaultwarden/`; 90-day Object Lock retention

On-demand backup:

    kubectl create job -n bitwarden --from=cronjob/vaultwarden-backup vaultwarden-backup-manual
    kubectl wait -n bitwarden --for=condition=complete job/vaultwarden-backup-manual --timeout=10m
    kubectl logs -n bitwarden job/vaultwarden-backup-manual -c upload
    aws s3 ls "s3://vaultwarden-backups-$(aws sts get-caller-identity --query Account --output text)/vaultwarden/"

Archive check; AWS identity with bucket read access:

    bucket="vaultwarden-backups-$(aws sts get-caller-identity --query Account --output text)"
    aws s3 cp "s3://$bucket/vaultwarden/TIMESTAMP.tar.gz" vaultwarden.tar.gz
    mkdir -p vaultwarden-restore
    tar -xzf vaultwarden.tar.gz -C vaultwarden-restore
    mkdir -p vaultwarden-restore/data
    tar -xzf vaultwarden-restore/data.tar.gz -C vaultwarden-restore/data
    docker run --rm -v "$PWD/vaultwarden-restore:/backup:ro" postgres:16.3-alpine3.20 pg_restore --list /backup/postgres.dump

### cert-manager issuers

Terraform module: `cert-manager-issuers/`
Root: `envs/mhemeryck/cert-manager-issuers/`
Production and staging ClusterIssuers are imported into the S3-backed Terraform state.
cert-manager v1.15.1 itself is still installed from the upstream release manifest:

    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.1/cert-manager.yaml

If managing that external installation becomes necessary, use a separate Terraform root with a pinned manifest and import the existing CRDs and workloads before applying changes.
If the webhook rejects changes because its CA expired, rotate its generated `cert-manager-webhook-ca` Secret in the `cert-manager` namespace and verify the webhook trust bundle refreshes before retrying.

## Kubernetes manifests

Facturette application resources and backups are managed from `facturette/infra/` in the Facturette repository

### Goalkeepr bootstrap

Terraform module: `goalkeepr-bootstrap/`
Root: `envs/mhemeryck/goalkeepr-bootstrap/`
The existing namespace, service account, Role, RoleBinding and token Secret are imported into the S3-backed Terraform state.

### Facturette bootstrap

Terraform module: `facturette-bootstrap/`
Root: `envs/mhemeryck/facturette-bootstrap/`
The existing `facturette` namespace is imported into the S3-backed state; the service account, Role, RoleBinding and token Secret are managed here.
The application resources and backups are managed from `facturette/infra/` in the Facturette repository.
