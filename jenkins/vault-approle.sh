#!/bin/bash

set -e
echo "🎯 Configuring Vault AppRole for Jenkins..."

VAULT_POD=$(kubectl get pod -n infrastructure -l app=vault -o jsonpath="{.items[0].metadata.name}")

kubectl exec -it $VAULT_POD -n infrastructure -- vault auth enable approle
kubectl exec -it $VAULT_POD -n infrastructure -- vault policy write jenkins /vault/policy.hcl

kubectl exec -it $VAULT_POD -n infrastructure -- vault write auth/approle/role/jenkins \
    secret_id_ttl=0 \
    token_ttl=20m \
    token_max_ttl=60m \
    policies=jenkins

kubectl exec -it $VAULT_POD -n infrastructure -- vault read auth/approle/role/jenkins/role-id
kubectl exec -it $VAULT_POD -n infrastructure -- vault write -f auth/approle/role/jenkins/secret-id
