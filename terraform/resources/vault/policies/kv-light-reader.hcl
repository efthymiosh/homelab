path "sys/mounts" {
  capabilities = ["read"]
}

path "kv/metadata/ssl/root-ca*" {
 capabilities = ["list", "read"]
}

path "kv/data/ssl/root-ca*" {
 capabilities = ["list", "read"]
}
