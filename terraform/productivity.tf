resource "nomad_job" "paperless-redis" {
  jobspec = file("./nomad/paperless/redis.hcl")
}

resource "nomad_job" "paperless_ngx" {
  jobspec = file("./nomad/paperless/paperless.hcl")
}

resource "nomad_job" "joplin" {
  jobspec = file("./nomad/joplin/joplin.hcl")
}

