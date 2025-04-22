# DevOps Containerized Infrastructure Setup

This repo sets up a production-ready DevOps stack in Kubernetes, including Jenkins, Vault, and Rancher. TLS is managed using cert-manager + Let's Encrypt + Cloudflare.

## 🌐 Subdomains
- Jenkins: `jenkins.mitechnology.org`
- Vault: `vault.mitechnology.org`
- Rancher: `rancher.mitechnology.org`

## 🧱 Stack
- Rancher (Kubernetes UI)
- Jenkins (Master + Agent)
- HashiCorp Vault (Secrets)
- cert-manager (TLS)
- NGINX Ingress Controller

## 🚀 Setup Steps
1. Create Cloudflare DNS A-records for each subdomain.
2. Manually create Cloudflare API token (do NOT commit).
3. Apply:
   ```bash
   bash deploy.sh
