variable "volume" {
  description = "The data volume for grafana"
}
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

    volume "grafana_data" {
      type = "csi"
      source = var.volume
      attachment_mode = "file-system"
      access_mode = "single-node-writer"
    }

    task "chown" {
      lifecycle {
        hook = "prestart"
      }
      driver = "docker"

      user = "root"

      config {
        image = "library/postgres:14.1"
        command = "bash"
        args = [
          "-c",
          "mkdir -p ${var.postgres_pgdata_dir}/pgdata && chown -v postgres:postgres ${var.postgres_pgdata_dir}/pgdata"
        ]
      }

      volume_mount {
        volume = "grafana_data"
        destination = var.postgres_pgdata_dir
      }
    }
    task "postgresql" {
      driver = "docker"

      user = "root"
      config {
        image = "library/postgres:14.1"
        ports = ["db"]
      }

      volume_mount {
        volume = "grafana_data"
        destination = var.postgres_pgdata_dir
      }

      env = {
        "POSTGRES_DB" = var.grafana_db
        "POSTGRES_USER" = var.grafana_user
        "POSTGRES_PASSWORD" = var.grafana_password
        "PGDATA" = "${var.postgres_pgdata_dir}/pgdata"
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
