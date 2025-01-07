job "joplin" {
  datacenters = ["homelab"]
  type = "service"

  group "joplin" {
    network {
      port "http" {
        to = 22300
      }
    }

    task "joplin" {
      driver = "docker"

      config {
        image = "joplin/server:latest"
        force_pull = true
        ports = ["http"]
      }

      vault {}
      template {
        env = true
        data = <<EOF
        APP_PORT=22300
        APP_BASE_URL=https://joplin.efhd.dev

        DB_CLIENT=pg
        {{ with secret `kv/data/nomad/shared/postgresql` }}
        POSTGRES_CONNECTION_STRING="postgresql://{{ .Data.data.user }}:{{ .Data.data.password }}@postgres.service.consul:5432/joplin?sslmode=require"
        {{ end }}

        NODE_EXTRA_CA_CERTS=/secrets/root-ca.pem
        MAILER_ENABLED=0
        EOF
        destination = "${NOMAD_SECRETS_DIR}/.env"
      }

      template {
        data = "{{ key `ssl/root_ca_cert` }}"
        destination = "${NOMAD_SECRETS_DIR}/root-ca.pem"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }

      service {
        name = "joplin"
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
