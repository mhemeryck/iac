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

The kubeconfig for the next step can be exported through

    terraform output -raw kubeconfig > kubeconfig

Set up kubectl; the kubeconfig file should just be in the folder ready

    export KUBECONFIG=`pwd`/kubeconfig

Merge the kubeconfig file afterwards:

    export KUBECONFIG~=/.kube/config:`pwd`/kubeconfig
    kubectl config view --flatten > out

[pass]: https://www.passwordstore.org/

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

    kubectl apply -f wekan.yaml

In case of restoring an older <dump> folder:

    kubectl cp <dump> default/mongodb-app-5cd84bf6df-ng5pv:/tmp/
    kubectl exec -it mongodb-app-7b46f9c87-pdbg5 -- bash
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
