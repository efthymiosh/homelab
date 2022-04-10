resource "nomad_job" "scylladb" {
  jobspec = file("nomad/temporal/scylladb.hcl")
  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "temporal" {
  jobspec = file("nomad/temporal/temporal.hcl")
  hcl2 {
    enabled = true
    vars    = {
      conf = file("nomad/temporal/temporal.yaml")
    }
  }
}
