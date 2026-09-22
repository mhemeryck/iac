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

In case of restoring an older <dump> folder:

    kubectl cp <dump> wekan/mongodb-0:/tmp/
    kubectl exec -it --namespace wekan mongodb-0 -- bash
    mongorestore /tmp/<dump>

## bitwarden

Provision some secrets (not in repo)

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: vault-secrets
type: Opaque
stringData:
  admin_token: "..."
  yubico_client_id: "..."
  yubico_secret_key: "..."
---
apiVersion: v1
kind: Secret
metadata:
  name: postgres
type: Opaque
stringData:
  password: "..."
  database_url: "postgresql://<username>:<password>@<host>:<port>"
```

Applying those secrets:

    kubectl apply -f secrets.yaml

Setup bitwarden deployment

    kubectl apply -f bitwarden.yaml

Create a backup of the postgres database

    kubectl exec -it postgres-0 -- bash
    pg_dump -U postgres <out.sql>

Restore backup of the postgres database

    kubectl exec -it postgres-0 -- bash
    psql -U postgres -f <out.sql>
