resource "nomad_job" "ory_keto" {
  jobspec = file("./nomad/ory/keto.hcl")
}

resource "nomad_job" "ory-postgres" {
  jobspec = file("./nomad/ory/postgres.hcl")
}
