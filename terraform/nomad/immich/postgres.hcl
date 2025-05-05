variable "immich_db" {
  description = "immich DB name"
  default = "immich"
}
variable "immich_user" {
  description = "immich DB username"
  default = "immich"
}
variable "immich_pass" {
  description = "immich DB password"
}

job "immich_postgres" {
  datacenters = ["homelab"]
  type = "service"

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "snu2"
  }

  group "server" {

    restart {
      attempts = 3
      interval = "2m"
      delay = "25s"
      mode = "delay"
    }

    network {
      port "db" {
        static = 5432
      }
    }

    task "postgresql" {
      driver = "docker"

      user = "root"
      config {
        image = "tensorchord/pgvecto-rs:pg14-v0.2.1"
        ports = ["db"]
        mount {
          type = "volume"
          target = "/usr/local/psql/data"
          source = "immich_postgresql_data"
        }
      }

      env = {
        "POSTGRES_DB" = var.immich_db
        "POSTGRES_USER" = var.immich_user
        "POSTGRES_PASSWORD" = var.immich_pass
        "PGDATA" = "/usr/local/psql/data"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "postgresql-immich"
        port = "db"

        check {
          type     = "tcp"
          interval = "15s"
          timeout  = "2s"
        }
      }
    }
  }
}
