#!/usr/bin/env bash

# Quick-and-dirty script to reach the instance and grab the kubeconfig file

# get ssh key
terraform output -raw private_key > id_rsa
chmod 400 id_rsa

# get the node ip
IP=$(terraform output -raw ip)

# get the kubeconfig output
KUBECONFIG=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i id_rsa "root@${IP}" cat /etc/rancher/k3s/k3s.yaml)

# drop the key file
rm -f id_rsa

# ensure we have json output
jq -n --arg kubeconfig "$KUBECONFIG" '{"kubeconfig":$kubeconfig}'
