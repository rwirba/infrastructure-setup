### 📁 rancher/README.md
```markdown
# Rancher Setup

## Prerequisites
- cert-manager already installed and issuing valid certificates
- `rancher.mitechnology.org` A record pointing to public IP

## Installation
```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
kubectl create namespace infrastructure

helm install rancher rancher-latest/rancher \
  --namespace infrastructure \
  --set hostname=rancher.mitechnology.org \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=admin@mitechnology.org \
  --set letsEncrypt.ingress.class=nginx
```

Monitor Rancher UI via browser after pods are ready:
```
https://rancher.mitechnology.org
```
```

---