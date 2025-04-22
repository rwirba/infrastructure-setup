#!/bin/bash
set -e

echo "📦 Ensuring Helm is installed..."
if ! command -v helm &> /dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "📦 Creating namespaces..."
kubectl create namespace infrastructure --dry-run=client -o yaml | kubectl apply -f -

echo "🔧 Installing cert-manager..."
kubectl apply -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io && helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace infrastructure \
  --set installCRDs=true

echo "🔐 Applying ClusterIssuer..."
kubectl apply -f cert-manager/cluster-issuer.yaml

echo "🚀 Deploying Rancher..."
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest && helm repo update
helm install rancher rancher-latest/rancher \
  --namespace infrastructure \
  --set hostname=rancher.mitechnology.org \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=admin@mitechnology.org

echo "🐳 Deploying Vault..."
kubectl apply -f vault/service.yaml
kubectl apply -f ingress/vault-ingress.yaml

echo "⚙️ Deploying Jenkins..."
kubectl apply -f jenkins/pvc.yaml
kubectl apply -f ingress/jenkins-ingress.yaml

echo "✅ All components deployed!"
