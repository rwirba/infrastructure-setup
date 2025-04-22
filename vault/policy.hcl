
---

### ✅ `vault/policy.hcl`
```hcl
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
