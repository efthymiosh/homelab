resource "vault_policy" "admin" {
  name   = "admin"
  policy = file("resources/vault/policies/admin.hcl")
}

resource "vault_policy" "cert-issuer" {
  name   = "cert-issuer"
  policy = file("resources/vault/policies/cert-issuer.hcl")
}

resource "vault_policy" "nomad-workloads" {
  name   = "nomad-workloads"
  policy = file("resources/vault/policies/nomad-workloads.hcl")
}

resource "vault_policy" "kv-light-reader" {
  name   = "kv-light-reader"
  policy = file("resources/vault/policies/kv-light-reader.hcl")
}
