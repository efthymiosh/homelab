# Here be dragons. Since both `nomad.efthymios.net` and `consul.efthymios.net`
# pass through traefik, any changes will disrupt terraform. Move to 
# snu1.int.efth.eu:8500 / :4646 if any issues arise.

resource "nomad_job" "traefik" {
  jobspec = file("nomad/traefik/traefik.hcl")
  hcl2 {
    enabled = true
    vars    = {
      traefik_conf = file("nomad/traefik/traefik.yaml")
    }
  }
}
