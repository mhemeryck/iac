# Infrastructure as code

This is the repo that serves some personal stuff over at [mhemeryck.xyz]

The projects I did deploy were

- [cvsite] a static nginx container, containing my resume
- [wekan] an open-source alternative to [trello], which I use for my own planning
- [vaultwarden] open-source version of [bitwarden] to host own password manager

[mhemeryck.xyz]: https://mhemeryck.xyz
[terraform]: https://terraform.io
[k3s]: https://k3s.io
[cvsite]: https://github.com/mhemeryck/cvsite
[wekan]: https://wekan.github.io/
[trello]: https://trello.com/
[bitwarden]: https://bitwarden.com/
[vaultwarden]: https://github.com/dani-garcia/vaultwarden

## terraform

The devenv shares Terraform provider downloads across roots in `~/.cache/terraform/plugin-cache`.
Create that directory before running `terraform init` for the first time.
Terraform still keeps each root's modules and working data in its local `.terraform/` directory.

Apply terraform setup; I do get the token from [pass]

    export TF_VAR_hetzner_dns_token=`pass show hetzner_dns_token`
    export TF_VAR_hcloud_token=`pass show <mytoken>`

The module for managing the node and setting up k3s is in the `node` folder.
I do also have an `envs` folder to then use this module.
To run:

    cd envs/mhemeryck/node
    terraform init
    terraform apply

After this step, the node should be up and running.

The HCloud-only kubeconfig is stored in the SecretSpec `pass` entry `secretspec/iac/default/KUBECONFIG`.
Entering the devenv sets `KUBECONFIG`, so standard `kubectl` commands use the HCloud cluster.

[pass]: https://www.passwordstore.org/

## Terraform state

The shared Terraform state bucket is managed by the `state-backend` module.
It stores each independent Terraform root under its own key and uses S3 lockfiles.

To bootstrap it from scratch, temporarily omit the `backend "s3"` block, initialize and apply with local state, then restore the block and migrate the state:

    cd envs/mhemeryck/state-backend
    terraform init
    terraform apply
    terraform init -migrate-state

Its state is stored at `platform/state-backend/terraform.tfstate`.
Migrate other roots to the shared bucket only when they are next changed.

## GitHub Actions

The `github-actions` module creates the shared GitHub OpenID Connect provider and `home-github-actions` role.
`envs/mhemeryck/github-actions` instantiates the module.
The role trusts `master` workflows in `mhemeryck` repositories and has administrator access to the AWS account.

## cvsite

Add the deployment and service

    kubectl apply -f cvsite.yaml

## ingress / TLS

Add the cert-manager resources

    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.0/cert-manager.yaml

Add the cluster issuers

    kubectl apply -f issuer-letsencrypt.yaml

(optionally, also the staging one)

    kubectl apply -f issuer-letsencrypt-staging.yaml

## wekan

Set up wekan

    cd envs/mhemeryck/wekan
    terraform init
    terraform apply

The `mongodb-backup` CronJob dumps the `wekan` database daily at 02:00 (cluster time) and uploads a compressed archive to `s3://wekan-backups-<aws-account-id>/wekan/`.
The bucket retains backups for 90 days with Object Lock governance retention.
AWS upload credentials are stored in the Kubernetes Secret and Terraform state; restrict access to both.
To check a backup immediately after applying:

    kubectl create job --namespace wekan --from=cronjob/mongodb-backup mongodb-backup-manual
    kubectl wait --namespace wekan --for=condition=complete job/mongodb-backup-manual --timeout=10m
    kubectl logs --namespace wekan job/mongodb-backup-manual -c upload
    aws s3 ls s3://wekan-backups-$(aws sts get-caller-identity --query Account --output text)/wekan/

To test a restore, download an archive using an AWS identity with read access to the bucket, then restore it into an isolated MongoDB instance:

    aws s3 cp s3://wekan-backups-<aws-account-id>/wekan/<timestamp>.archive.gz ./wekan.archive.gz
    docker run -d --rm --name wekan-restore mongo:6.0.26-jammy
    docker cp ./wekan.archive.gz wekan-restore:/tmp/wekan.archive.gz
    docker exec wekan-restore mongorestore --gzip --archive=/tmp/wekan.archive.gz --nsInclude='wekan.*'
    docker exec wekan-restore mongosh --quiet --eval 'db.getSiblingDB("wekan").getCollectionNames()'
    docker stop wekan-restore

In case of restoring an older <dump> folder:

    kubectl cp <dump> wekan/mongodb-0:/tmp/
    kubectl exec -it --namespace wekan mongodb-0 -- bash
    mongorestore /tmp/<dump>

## vaultwarden

`envs/mhemeryck/vaultwarden` manages the existing `bitwarden` namespace, including its two Secrets and two data PVCs, in a separate S3-backed Terraform state.
The existing resources were imported without replacing or changing them.
Existing credentials are stored in state and left unchanged by Terraform, so no local `secrets.yaml` is needed to manage the deployment.
Terraform derives the Postgres `database_url` key from the imported `password` key without duplicating the password in HCL.
The state contains plaintext Secret values; restrict access to the state bucket accordingly.
The cert-manager TLS Secret remains managed by cert-manager.

Enter the devenv with a working kubeconfig and run:

    cd envs/mhemeryck/vaultwarden
    terraform init
    terraform plan
    terraform apply

Review the plan before applying, especially any proposed changes to the namespace, PVCs, Secrets, Deployment, or StatefulSet.
Remove any old local Vaultwarden secrets file once it is no longer needed.

Importing preserves the credentials already in Kubernetes, but the state alone is not a declarative source for recreating a lost Secret.
Daily backups for Postgres and Vaultwarden's `/data` volume are a separate follow-up.
