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

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "snu1"
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
        image = "library/postgres:14.1"
        ports = ["db"]
        mount {
          type = "volume"
          target = "/usr/local/psql/data"
          source = "postgresql_data"
        }
      }

      env = {
        "POSTGRES_DB" = var.grafana_db
        "POSTGRES_USER" = var.grafana_user
        "POSTGRES_PASSWORD" = var.grafana_password
        "PGDATA" = "/usr/local/psql/data"
      }

      resources {
        cpu    = 500
        memory = 512
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
