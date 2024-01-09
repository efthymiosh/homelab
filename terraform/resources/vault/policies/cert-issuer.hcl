path "pki/issue*" {
  capabilities = ["create","update"]
}

path "auth/token/renew" {
  capabilities = ["update"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}
