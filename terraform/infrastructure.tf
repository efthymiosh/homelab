resource "nomad_job" "docker-registry" {
  jobspec = file("nomad/docker-registry/registry.hcl")
  hcl2 {
    enabled = true
    vars = {
      conf = file("nomad/docker-registry/config.yml")
    }
  }
}
