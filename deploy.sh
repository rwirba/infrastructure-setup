# #!/bin/bash
# set -e

# NAMESPACE=infrastructure
# EMAIL=admin@mitechnology.org
# DOMAIN_RANCHER=rancher.mitechnology.org
# DOMAIN_JENKINS=jenkins.mitechnology.org
# DOMAIN_VAULT=vault.mitechnology.org

# echo "🧱 Installing prerequisites (Docker, kubectl, Helm, K3s)..."

# # Install Docker
# if ! command -v docker &> /dev/null; then
#   echo "📦 Installing Docker..."
#   apt-get update
#   apt-get install -y \
#     ca-certificates curl gnupg lsb-release software-properties-common

#   mkdir -p /etc/apt/keyrings
#   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
#   echo \
#     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
#     $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

#   apt-get update
#   apt-get install -y docker-ce docker-ce-cli containerd.io
# fi

# # Install kubectl
# if ! command -v kubectl &> /dev/null; then
#   echo "📦 Installing kubectl..."
#   curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
#   install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
#   rm kubectl
# fi

# # Install Helm
# if ! command -v helm &> /dev/null; then
#   echo "📦 Installing Helm..."
#   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
# fi

# # Install K3s (single-node cluster)
# if ! systemctl is-active --quiet k3s; then
#   echo "☸️ Installing K3s..."
#   curl -sfL https://get.k3s.io | sh -
#   export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
#   echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc
# fi

# # Verify cluster is ready
# echo "✅ Verifying K3s is up..."
# sleep 5
# kubectl get nodes

# # Create namespace
# echo "📦 Creating namespace: $NAMESPACE"
# kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# # Install cert-manager CRDs
# echo "🔧 Installing cert-manager CRDs..."
# kubectl apply -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.crds.yaml

# # Install cert-manager via Helm (safe check)
# if ! helm status cert-manager -n $NAMESPACE &>/dev/null; then
#   echo "🎯 Installing cert-manager via Helm..."
#   helm repo add jetstack https://charts.jetstack.io
#   helm repo update
#   helm install cert-manager jetstack/cert-manager \
#     --namespace $NAMESPACE \
#     --set installCRDs=false \
#     --create-namespace
# else
#   echo "ℹ️ cert-manager already installed"
# fi

# # Cloudflare token
# if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
#   echo "❌ CLOUDFLARE_API_TOKEN is not set. Export it first: export CLOUDFLARE_API_TOKEN=..."
#   exit 1
# fi

# echo "🔐 Creating Cloudflare secret..."
# kubectl create secret generic cloudflare-api-token-secret \
#   --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
#   -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# echo "🌍 Applying ClusterIssuer..."
# kubectl apply -f cert-manager/cluster-issuer.yaml

# echo "🚀 Installing Rancher..."
# helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
# helm repo update
# helm upgrade --install rancher rancher-latest/rancher \
#   --namespace $NAMESPACE \
#   --set hostname=$DOMAIN_RANCHER \
#   --set ingress.tls.source=letsEncrypt \
#   --set letsEncrypt.email=$EMAIL \
#   --set letsEncrypt.ingress.class=nginx \
#   --wait

# echo "🔒 Deploying Vault..."
# kubectl apply -f vault/service.yaml
# kubectl apply -f ingress/vault-ingress.yaml

# echo "🧰 Deploying Jenkins..."
# kubectl apply -f jenkins/pvc.yaml
# kubectl apply -f jenkins/service.yaml
# kubectl apply -f ingress/jenkins-ingress.yaml

# echo "🛡️ Applying RBAC..."
# kubectl apply -f rbac/jenkins-rbac.yaml
# kubectl apply -f rbac/vault-rbac.yaml
# kubectl apply -f rbac/rancher-rbac.yaml

# echo "✅ All components deployed successfully!"
#!/bin/bash
set -e

NAMESPACE=infrastructure
EMAIL=admin@mitechnology.org
DOMAIN_RANCHER=rancher.mitechnology.org
DOMAIN_JENKINS=jenkins.mitechnology.org
DOMAIN_VAULT=vault.mitechnology.org

# 0. Run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Please run this script as root (sudo ./deploy.sh)"
  exit 1
fi

# 1. Install Docker
if ! command -v docker &> /dev/null; then
  echo "📦 Installing Docker..."
  apt-get update
  apt-get install -y ca-certificates curl gnupg lsb-release
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# 2. Install K3s
if ! command -v k3s &> /dev/null && ! systemctl is-active --quiet k3s; then
  echo "🔧 Installing K3s..."
  curl -sfL https://get.k3s.io | sh -
  sleep 10
fi

# 3. Export kubeconfig
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# 4. Install kubectl manually (linked to k3s)
if ! command -v kubectl &> /dev/null; then
  ln -s /usr/local/bin/kubectl /usr/bin/kubectl || true
fi

# 5. Install Helm
if ! command -v helm &> /dev/null; then
  echo "📦 Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# 6. Create namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 7. Cert-Manager Setup
kubectl apply -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.crds.yaml

helm repo add jetstack https://charts.jetstack.io || true
helm repo update

if ! helm status cert-manager -n $NAMESPACE &> /dev/null; then
  echo "🔧 Installing cert-manager..."
  helm install cert-manager jetstack/cert-manager \
    --namespace $NAMESPACE \
    --set installCRDs=true
else
  echo "ℹ️ cert-manager already installed. Skipping..."
fi

# 8. Check Cloudflare API Token
if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
  echo "❌ CLOUDFLARE_API_TOKEN is not set. Please run:"
  echo "   export CLOUDFLARE_API_TOKEN=your_token"
  exit 1
fi

# 9. Cloudflare DNS secret
kubectl create secret generic cloudflare-api-token-secret \
  --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
  -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 10. Apply ClusterIssuer
kubectl apply -f cert-manager/cluster-issuer.yaml

# 11. Install Rancher
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest || true
helm repo update

if ! helm status rancher -n $NAMESPACE &> /dev/null; then
  echo "🚀 Installing Rancher..."
  helm install rancher rancher-latest/rancher \
    --namespace $NAMESPACE \
    --set hostname=$DOMAIN_RANCHER \
    --set ingress.tls.source=letsEncrypt \
    --set letsEncrypt.email=$EMAIL \
    --set letsEncrypt.ingress.class=nginx
else
  echo "ℹ️ Rancher already installed. Skipping..."
fi

# 12. Vault
kubectl apply -f vault/service.yaml
kubectl apply -f ingress/vault-ingress.yaml

# 13. Jenkins
kubectl apply -f jenkins/pvc.yaml
kubectl apply -f jenkins/service.yaml
kubectl apply -f ingress/jenkins-ingress.yaml

# 14. RBAC
kubectl apply -f rbac/jenkins-rbac.yaml
kubectl apply -f rbac/vault-rbac.yaml
kubectl apply -f rbac/rancher-rbac.yaml

echo "✅ All infrastructure components deployed successfully!"
echo "🔐 Rancher password: "
kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{"\n"}}' || true

