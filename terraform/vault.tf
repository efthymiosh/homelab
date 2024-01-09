resource "vault_policy" "admin" {
  name   = "admin"
  policy = file("resources/vault/policies/admin.hcl")
}

resource "vault_policy" "cert-issuer" {
  name   = "cert-issuer"
  policy = file("resources/vault/policies/cert-issuer.hcl")
}
