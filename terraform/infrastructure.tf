resource "nomad_job" "docker-registry" {
  jobspec = file("nomad/docker-registry/registry.hcl")
  hcl2 {
    vars = {
      conf = file("nomad/docker-registry/config.yml")
    }
  }
}

locals {
  dns_domains = toset([
    "efthymios.net",
    "efthymios.me",
    "efhd.dev",
    "efhd.eu",
  ])
}

resource "nomad_job" "certbot" {
  for_each = local.dns_domains

  jobspec = templatefile("nomad/certbot/certbot.tmpl.hcl", {
    domain = each.key
  })
}
