# Infrastructure as code

terraform setup for personal projects

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
