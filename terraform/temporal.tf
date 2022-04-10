resource "nomad_job" "scylladb" {
  jobspec = file("nomad/temporal/scylladb.hcl")
  hcl2 {
    enabled = true
  }
}
