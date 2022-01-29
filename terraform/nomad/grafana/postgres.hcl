variable "grafana_db" {
  description = "Grafana DB name"
  default = "grafana"
}
variable "grafana_user" {
  description = "Grafana DB username"
  default = "grafana"
}
variable "grafana_password" {
  description = "Grafana DB password"
}
variable "postgres_pgdata_dir" {
  description = "The postgres data directory"
  default = "/var/lib/postgresql/data"
}

job "grafana_postgres" {
  datacenters = ["homelab"]
  type = "service"

  group "server" {

    network {
      port "db" {
        static = 5432
      }
    }

    ephemeral_disk {
      sticky  = true
      migrate = true
      size    = 200
    }

    task "postgresql" {
      driver = "docker"

      user = "root"
      config {
        image = "library/postgres:14.1"
        ports = ["db"]
      }

      env = {
        "POSTGRES_DB" = var.grafana_db
        "POSTGRES_USER" = var.grafana_user
        "POSTGRES_PASSWORD" = var.grafana_password
        "PGDATA" = "${NOMAD_ALLOC_DIR}/data"
      }

      resources {
        cpu    = 500
        memory = 256
      }

      service {
        name = "postgresql-server"
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
