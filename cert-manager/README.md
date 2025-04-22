# cert-manager Setup

1. Install cert-manager CRDs:
   ```bash
   kubectl apply -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.crds.yaml

2. Add Helm repo and install:
   ```bash
   helm repo add jetstack https://charts.jetstack.io
   helm upgrade --install cert-manager jetstack/cert-manager --namespace infrastructure --create-namespace --set installCRDs=true

 3. Create Cloudflare token secret:
   ```bash
   kubectl create secret generic cloudflare-api-token-secret \
   --from-literal=api-token=<YOUR_TOKEN> \
   --namespace infrastructure

4. Apply the cluster issuer:
   ```bash
   kubectl apply -f cluster-issuer.yaml
