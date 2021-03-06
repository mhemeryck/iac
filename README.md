# Infrastructure as code

This is a first project where I wanted to apply some newly learned concepts in the real world, specifically:

- [terraform] for provisioning the infrastructure
- [k3sup] for bootstrapping a minimal one-node [k3s]-based kubernetes cluster
- [traefik] -- built into k3s as an ingress controller and TLS termination
- [cert-manager] for automatically supporting TLS for the different endpoints

The projects I did deploy were

- [cvsite] a static nginx container, containing my resume
- [wekan] an open-source alternative to [trello], which I use for my own planning

[terraform]: https://terraform.io
[k3sup]: https://k3sup.dev
[k3s]: https://k3s.io
[traefik]: https://containo.us/traefik/
[cert-manager]: https://cert-manager.io/docs/installation/kubernetes/
[cvsite]: https://github.com/mhemeryck/cvsite
[wekan]: https://wekan.github.io/
[trello]: https://trello.com/

## terraform

Apply terraform setup; I do get the token from [pass]

    export TF_VAR_do_token=`pass show <mytoken>`
    export TF_VAR_hcloud_token=`pass show <mytoken>`
    terraform apply

[pass]: https://www.passwordstore.org/

## provision k3s

Bootstrap

    k3sup install --ip $(terraform output ip) --user root --ssh-key=kube_key --local-path=./kubeconfig

get the kubeconfig file afterwards

    k3sup install --ip $(terraform output ip) --user root --ssh-key=kube_key --local-path=./kubeconfig --skip-install

Set up kubectl; the kubeconfig file should just be in the folder ready

    export KUBECONFIG=`pwd`/kubeconfig

Merge the kubeconfig file afterwards:

    export KUBECONFIG~=/.kube/config:`pwd`/kubeconfig
    kubectl config view --flatten > out

## cvsite

Add the deployment and service

    kubectl apply -f cvsite.yaml

## ingress / TLS

Add the cert-manager resources

    kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.16.1/cert-manager.yaml

Add the cluster issuers

    kubectl apply -f issuer-letsencrypt.yaml

(optionally, also the staging one)

    kubectl apply -f issuer-letsencrypt-staging.yaml

Add the ingress, referencing the cluster TLS issuer:

    kubectl apply -f ingress.yaml

## wekan

Setup mongodb

    kubectl apply -f mongo.yaml

In case of restoring an older <dump> folder:

    kubectl cp <dump> default/mongodb-app-5cd84bf6df-ng5pv:/tmp/
    kubectl exec -it mongodb-app-7b46f9c87-pdbg5 -- bash
    mongorestore /tmp/<dump>

Set up wekan

    kubectl apply -f wekan.yaml
