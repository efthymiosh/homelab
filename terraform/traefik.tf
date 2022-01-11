resource "nomad_job" "traefik" {
  jobspec = file("nomad/traefik/traefik.hcl")
  hcl2 {
    enabled = true
    vars    = {
      traefik_conf = file("nomad/traefik/traefik.yaml")
    }
  }
}
