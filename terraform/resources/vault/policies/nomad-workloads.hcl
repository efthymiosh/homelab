path "kv/data/nomad/{{identity.entity.aliases.auth_jwt_d2e8dcff.metadata.nomad_job_id}}/*" {
  capabilities = ["read"]
}

path "kv/data/nomad/{{identity.entity.aliases.auth_jwt_d2e8dcff.metadata.nomad_job_id}}" {
  capabilities = ["read"]
}

path "kv/data/nomad/shared/*" {
  capabilities = ["read"]
}

path "kv/data/nomad/shared/generated/*" {
  capabilities = ["read", "create", "update"]
}

path "kv/metadata/*" {
  capabilities = ["list"]
}

path "pki/issue/nomad-workloads*" {
  capabilities = ["create","update"]
}
