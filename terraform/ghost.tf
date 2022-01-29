resource "nomad_job" "ghost" {
  jobspec = file("nomad/ghost/ghost.hcl")
  hcl2 {
    enabled = true
  }
}
