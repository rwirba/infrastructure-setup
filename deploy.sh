#!/bin/bash
set -e

NAMESPACE=infrastructure
EMAIL=admin@mitechnology.org
DOMAIN_RANCHER=rancher.mitechnology.org
DOMAIN_JENKINS=jenkins.mitechnology.org
DOMAIN_VAULT=vault.mitechnology.org

echo "🧱 Installing prerequisites (Docker, kubectl, Helm)..."

# Install Docker
if ! command -v docker &> /dev/null; then
  echo "📦 Installing Docker..."
  apt-get update
  apt-get install -y \
    ca-certificates curl gnupg lsb-release

  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# Install kubectl
if ! command -v kubectl &> /dev/null; then
  echo "📦 Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
fi

# Install Helm
if ! command -v helm &> /dev/null; then
  echo "📦 Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "📦 Creating namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "🔧 Installing cert-manager CRDs..."
kubectl apply -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.crds.yaml

echo "🎯 Installing cert-manager via Helm..."
helm repo add jetstack https://charts.jetstack.io && helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace $NAMESPACE \
  --set installCRDs=false \
  --skip-crds

echo "🔐 Creating Cloudflare secret..."
if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
  echo "❌ CLOUDFLARE_API_TOKEN is not set. Export it first: export CLOUDFLARE_API_TOKEN=..."
  exit 1
fi

kubectl create secret generic cloudflare-api-token-secret \
  --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
  -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "🌍 Applying ClusterIssuer..."
kubectl apply -f cert-manager/cluster-issuer.yaml

echo "🚀 Installing Rancher..."
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
helm install rancher rancher-latest/rancher \
  --namespace $NAMESPACE \
  --set hostname=$DOMAIN_RANCHER \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=$EMAIL \
  --set letsEncrypt.ingress.class=nginx

echo "🔒 Deploying Vault..."
kubectl apply -f vault/service.yaml
kubectl apply -f ingress/vault-ingress.yaml

echo "🧰 Deploying Jenkins..."
kubectl apply -f jenkins/pvc.yaml
kubectl apply -f jenkins/service.yaml
kubectl apply -f ingress/jenkins-ingress.yaml

echo "🛡️ Applying RBAC..."
kubectl apply -f rbac/jenkins-rbac.yaml
kubectl apply -f rbac/vault-rbac.yaml
kubectl apply -f rbac/rancher-rbac.yaml

echo "✅ All components deployed successfully!"
