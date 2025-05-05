job "postgres" {
  datacenters = ["homelab"]
  type = "service"

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "aero1"
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
        image = "library/postgres:16"
        ports = ["db"]
        args = [
          "-c", "ssl_key_file=${NOMAD_SECRETS_DIR}/server.key",
          "-c", "ssl_cert_file=${NOMAD_SECRETS_DIR}/server.pem",
          "-c", "ssl=on",
        ]
        mount {
          type = "volume"
          target = "/usr/local/psql/data"
          source = "postgresql_data"
        }
      }

      vault {}
      template {
        env = true
        data = <<EOF
        POSTGRES_DB=postgres
        {{ with secret `kv/data/nomad/shared/postgresql` }}
        POSTGRES_USER={{ .Data.data.user }}
        POSTGRES_PASSWORD={{ .Data.data.password }}
        {{ end }}
        PGDATA=/usr/local/psql/data
        EOF
        destination = "${NOMAD_SECRETS_DIR}/.env"
      }

      template {
        data = <<EOF
        {{- with secret `pki/issue/nomad-workloads`
        `common_name=postgres.service.consul`
        `ttl=7d`
        `alt_names=postgres.service.homelab.dc.consul`
        -}}
        {{- .Data.certificate -}}
        {{- printf "\n" -}}
        {{- .Data.issuing_ca -}}
        {{- end -}}
        EOF
        destination = "${NOMAD_SECRETS_DIR}/server.pem"
        change_mode = "script"
        change_script {
          command = "su"
          args = [
            "-", "postgres", "-c",
            "/usr/lib/postgresql/16/bin/pg_ctl reload -D /usr/local/psql/data"
          ]
        }
        perms = "600"
        uid   = 999
      }
      template {
        data = <<EOF
        {{- with secret `pki/issue/nomad-workloads`
        `common_name=postgres.service.consul`
        `ttl=7d`
        `alt_names=postgres.service.homelab.dc.consul`
        -}}
        {{- .Data.private_key }}
        {{- end -}}
        EOF
        destination = "${NOMAD_SECRETS_DIR}/server.key"
        change_mode = "script"
        change_script {
          command = "su"
          args = [
            "-", "postgres", "-c",
            "/usr/lib/postgresql/16/bin/pg_ctl reload -D /usr/local/psql/data"
          ]
        }
        perms = "600"
        uid   = 999
      }

      resources {
        cpu    = 2500
        memory = 1024
      }

      service {
        name = "postgres"
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
