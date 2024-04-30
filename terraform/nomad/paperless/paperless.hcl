job "paperless" {
  datacenters = ["homelab"]
  type = "service"

  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "aero1"
  }

  group "paperless" {
    network {
      port "http" {
        to = 8000
      }
    }

    task "paperless" {
      driver = "docker"

      config {
        image = "ghcr.io/paperless-ngx/paperless-ngx:latest"
        ports = ["http"]
        mount {
          type = "volume"
          target = "/usr/local/psql/data"
          source = "paperless_data"
        }
        mount {
          type = "bind"
          target = "/usr/src/paperless/data"
          source = "/data/paperless/data"
        }
        mount {
          type = "bind"
          target = "/usr/src/paperless/media"
          source = "/data/paperless/media"
        }
      }

      vault {}
      template {
        env = true
        data = <<EOF
        PAPERLESS_REDIS="rediss://redis-paperless.service.consul:6379?ssl_ca_certs=/secrets/root-ca.pem"
        PAPERLESS_DBHOST=postgres.service.consul

        {{ with secret `kv/data/nomad/shared/postgresql` }}
        PAPERLESS_DBUSER={{ .Data.data.user }}
        PAPERLESS_DBPASS={{ .Data.data.password }}
        {{ end }}

        PAPERLESS_DBSSLMODE=verify-ca
        PAPERLESS_DBSSLROOTCERT=/secrets/root-ca.pem
        PAPERLESS_URL=https://paperless.efhd.dev

        {{ with secret `kv/data/nomad/paperless` }}
        PAPERLESS_SECRET_KEY={{ .Data.data.secret_key }}
        PAPERLESS_ADMIN_USER=admin
        PAPERLESS_ADMIN_PASSWORD="{{ .Data.data.admin_pass }}"
        {{ end }}

        PAPERLESS_DISABLE_REGULAR_LOGIN=false
        PAPERLESS_ACCOUNT_ALLOW_SIGNUPS=true
        PAPERLESS_OCR_LANGUAGES=eng
        PAPERLESS_TASK_WORKERS=2
        PAPERLESS_THREADS_PER_WORKER=4
        PAPERLESS_TIME_ZONE=Europe/Athens
        EOF
        destination = "${NOMAD_SECRETS_DIR}/.env"
      }

      template {
        data = "{{ key `ssl/root_ca_cert` }}"
        destination = "${NOMAD_SECRETS_DIR}/root-ca.pem"
      }

      resources {
        cpu    = 2500
        memory = 2048
      }

      service {
        name = "paperless"
        port = "http"
        tags = [
          "routed"
        ]

        check {
          type     = "tcp"
          interval = "15s"
          timeout  = "2s"
        }
      }
    }
  }
}
