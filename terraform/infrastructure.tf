resource "nomad_job" "docker-registry" {
  jobspec = file("nomad/docker-registry/registry.hcl")
  hcl2 {
    vars = {
      conf = file("nomad/docker-registry/config.yml")
    }
  }
}

resource "nomad_job" "cloudflared" {
  jobspec = file("nomad/cloudflared/cloudflared.hcl")
}


locals {
  dns_domains = toset([
    "efthymios.net",
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

# general purpose postgresql
resource "nomad_job" "postgres" {
  jobspec = file("./nomad/postgres/postgres.hcl")
}
