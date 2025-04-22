#!/bin/bash
kubectl create namespace infrastructure

helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

helm upgrade --install rancher rancher-latest/rancher \
  --namespace infrastructure \
  --set hostname=rancher.mycompany.dev \
  --set replicas=1 \
  --set bootstrapPassword=admin
