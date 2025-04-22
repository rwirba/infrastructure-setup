# Vault Setup

## Description
HashiCorp Vault is used to securely store secrets (like AWS, GitHub, DockerHub credentials) and expose them via AppRole for Jenkins.

## Access
- **Vault UI:** `https://vault.mitechnology.org`
- **TLS:** Handled by cert-manager + Let's Encrypt

## Usage
1. Vault is deployed via `vault/deployment.yaml`
2. Init/unseal Vault via:
   ```bash
   ./vault/vault-init.sh

3. Apply default policy:
```bash
vault policy write jenkins ./policy.hcl

4. Create AppRole:

```bash
./jenkins/vault-approle.sh

