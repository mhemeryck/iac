#!/usr/bin/env zsh

# Apply cert manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.1/cert-manager.yaml

# Apply cluster issuers
kubectl apply -f issuer-letsencrypt-staging.yaml
kubectl apply -f issuer-letsencrypt.yaml

# Apply cvsite
kubectl apply -f cvsite.yaml

