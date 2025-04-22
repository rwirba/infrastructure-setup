#!/bin/bash

set -e
echo "🔐 Initializing Vault..."

kubectl exec -it deploy/vault -n infrastructure -- vault operator init -key-shares=1 -key-threshold=1 -format=json > vault-init.json

UNSEAL_KEY=$(jq -r '.unseal_keys_b64[0]' vault-init.json)
ROOT_TOKEN=$(jq -r '.root_token' vault-init.json)

echo "Unsealing..."
kubectl exec -it deploy/vault -n infrastructure -- vault operator unseal $UNSEAL_KEY

echo $ROOT_TOKEN > vault-root-token.txt
echo "✅ Vault initialized and unsealed. Root token saved."
