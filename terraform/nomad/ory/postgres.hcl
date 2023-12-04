job "ory_postgres" {
  datacenters = ["homelab"]
  type = "service"

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "snu3"
  }

  group "server" {

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
          source = "ory_postgresql_data"
        }
        mount {
          type = "bind"
          source = "..${NOMAD_ALLOC_DIR}/init_ory.sql"
          target = "/docker-entrypoint-initdb.d/init_ory.sql"
          readonly = false
        }
      }

      template {
        env = true
        data = <<EOF
        POSTGRES_DB="keto"
        POSTGRES_USER="{{ key `postgres/ory/user` }}"
        POSTGRES_PASSWORD="{{ key `postgres/ory/password` }}"
        PGDATA="/usr/local/psql/data"
        EOF
        destination = "${NOMAD_SECRETS_DIR}/.env"
      }

      template {
        data = <<EOF
        CREATE DATABASE kratos;
        EOF
        destination = "${NOMAD_ALLOC_DIR}/init_ory.sql"
      }

      resources {
        cpu    = 250
        memory = 256
      }

      service {
        name = "postgresql-ory"
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
