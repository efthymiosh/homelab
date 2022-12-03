resource "nomad_job" "plex" {
  jobspec = file("nomad/plex/plex.hcl")
  hcl2 {
    enabled = true
  }
}
