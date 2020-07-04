# Infrastructure as code

terraform setup for personal projects

todo:
- [x] terraform infra setup: single node
- [x] provision k3s
- [x] add simple cvsite static web service
- [x] protect ingress with TLS
- [ ] migrate wekan
- [ ] migrate domain name control under wekan

some future ideas:
- multi-node setup? costs will probably get higher, not sure if it'll be still worth it
- git repo? ci / cd?

## terraform

  export TF_VAR_do_token=`pass show digitalocean_dns_token`
  terraform apply

## provision k3s

  k3sup install --ip $(terraform output ip) --user root --ssh-key=kube_key --local-path=./kubeconfig

## cvsite

Set up kubectl

  export KUBECONFIG=`pwd`/kubeconfig

Add the deployment and service

  kubectl apply -f cvsite.yaml

## ingress / TLS

Add the cert-manager resources

  kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.1/cert-manager.yaml

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

  kubectl cp dump/ default/mongodb-app-5cd84bf6df-ng5pv:/tmp/
  kubectl exec -it mongodb-app-7b46f9c87-pdbg5 -- bash
  mongorestore /tmp/dump/

Set up wekan

  kubectl apply -f wekan.yaml
