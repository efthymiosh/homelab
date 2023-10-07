resource "nomad_job" "immich" {
  jobspec = file("nomad/immich/immich.hcl")
  hcl2 {
    enabled = true
    vars = {
      immich_pass = var.immich_db_pass
    }
  }
}

resource "nomad_job" "immich-redis" {
  jobspec = file("nomad/immich/redis.hcl")
  hcl2 {
    enabled = true
  }
}

resource "nomad_job" "immich-postgres" {
  jobspec = file("nomad/immich/postgres.hcl")
  hcl2 {
    enabled = true
    vars = {
      immich_pass = var.immich_db_pass
    }
  }
}
