### 📁 jenkins/README.md
```markdown
# Jenkins (Master)

## Docker Image
Custom Jenkins image using Ubuntu base with:
- Jenkins LTS
- Docker CLI
- Helm & kubectl
- OpenJDK 11

## PVC
Ensure `jenkins-pvc.yaml` is deployed in namespace `infrastructure`:
```bash
kubectl apply -f pvc.yaml
```

## Ingress
Uses `jenkins.mitechnology.org` and TLS from cert-manager. See `ingress/jenkins-ingress.yaml`.

## Vault Integration
Ensure Vault is running and `VAULT_ADDR`, `VAULT_TOKEN` are available to Jenkins via env or secrets.
```

---