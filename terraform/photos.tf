resource "nomad_job" "immich" {
  jobspec = file("nomad/immich/immich.hcl")
  hcl2 {
    vars = {
      immich_pass = var.immich_db_pass
    }
  }
}

resource "nomad_job" "immich-redis" {
  jobspec = file("nomad/immich/redis.hcl")
}

resource "nomad_job" "immich-postgres" {
  jobspec = file("nomad/immich/postgres.hcl")
  hcl2 {
    vars = {
      immich_pass = var.immich_db_pass
    }
  }
}
