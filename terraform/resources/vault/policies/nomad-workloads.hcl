path "kv/data/nomad/{{identity.entity.aliases.auth_jwt_d2e8dcff.metadata.nomad_job_id}}/*" {
  capabilities = ["read"]
}

path "kv/data/nomad/{{identity.entity.aliases.auth_jwt_d2e8dcff.metadata.nomad_job_id}}" {
  capabilities = ["read"]
}

path "kv/metadata/nomad/*" {
  capabilities = ["list"]
}

path "kv/metadata/*" {
  capabilities = ["list"]
}

